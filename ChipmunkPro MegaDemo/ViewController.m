//
//  ViewController.m
//  ChipmunkPro MegaDemo
//
//  Created by Scott Lembcke on 12/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#import "ObjectiveChipmunk.h"
#import "transform.h"

#if __ARM_NEON__
#import "arm_neon.h"
#endif

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_FWIDTH,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    ATTRIB_COLOR,
    NUM_ATTRIBUTES
};

typedef struct Color {GLfloat r, g, b, a;} Color;
typedef struct Vertex {cpVect vertex, texcoord; Color color;} Vertex;
typedef struct Triangle {Vertex a, b, c;} Triangle;

@interface ViewController () {
    GLuint _program;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
		
		GLuint _triangleCount;
		Triangle *_triangles;
}
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation ViewController

@synthesize context = _context;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
		self.preferredFramesPerSecond = 60;
		
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
		view.drawableColorFormat = GLKViewDrawableColorFormatRGB565;
    view.context = self.context;
    
    [self setupGL];
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

#define WIDTH 1.5

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
		
    glClearColor(1.0, 1.0, 1.0, 1.0);
		
		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    [self loadShaders];
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
		
		Color red = {1.0, 0.0, 0.0, 1.0};
		Color black = {0.0, 0.0, 0.0, 1.0};
		Color clear = {0.0, 0.0, 0.0, 1.0};
		
		cpFloat size = 10.0;
		int vert_count = 5;
		cpVect verts[vert_count];
		for(int i=0; i<vert_count; i++){
			cpFloat angle = -2*M_PI*i/((cpFloat)vert_count);
			verts[i] = cpv(size*cos(angle), size*sin(angle));
		}
		
		struct ExtrudeVerts {cpVect offset, n1, n2;};
		struct ExtrudeVerts extrude[vert_count];
		bzero(extrude, sizeof(struct ExtrudeVerts)*vert_count);
		
		for(int i=0; i<vert_count; i++){
			cpVect v0 = verts[(i-1+vert_count)%vert_count];
			cpVect v1 = verts[i];
			cpVect v2 = verts[(i+1)%vert_count];
			
			cpVect n1 = cpvnormalize(cpvperp(cpvsub(v1, v0)));
			cpVect n2 = cpvnormalize(cpvperp(cpvsub(v2, v1)));
			
			cpVect offset = cpvmult(cpvadd(n1, n2), 1.0/(cpvdot(n1, n2) + 1.0));
			extrude[i] = (struct ExtrudeVerts){offset, n1, n2};
		}
		
		int border_verts = 6;
		_triangleCount = (vert_count - 2) + border_verts*vert_count;
		_triangles = calloc(_triangleCount, sizeof(Triangle));
		
		for(int i=0; i<vert_count-2; i++){
			_triangles[i] = (Triangle){
				{verts[0], cpvzero, red},
				{verts[i+1], cpvzero, red},
				{verts[i+2], cpvzero, red},
			};
		}
		
		for(int i=0; i<vert_count; i++){
			int j = (i+1)%vert_count;
			cpVect v0 = verts[i];
			cpVect v1 = verts[j];
			
			cpVect offset0 = extrude[i].offset;
			cpVect offset1 = extrude[j].offset;
			cpVect inner0 = cpvsub(v0, cpvmult(offset0, WIDTH));
			cpVect inner1 = cpvsub(v1, cpvmult(offset1, WIDTH));
//			cpVect outer0 = cpvadd(v0, cpvmult(offset0, WIDTH));
			cpVect outer1 = cpvadd(v1, cpvmult(offset1, WIDTH));
			
			cpVect n0 = extrude[i].n2;
			cpVect n1 = extrude[j].n2;
			cpVect e1 = cpvadd(v0, cpvmult(n0, WIDTH));
			cpVect e2 = cpvadd(v1, cpvmult(n0, WIDTH));
			cpVect e3 = cpvadd(v1, cpvmult(n1, WIDTH));
			
			_triangles[vert_count-2 + border_verts*i + 0] = (Triangle){{inner0, cpvneg(n0), clear}, {inner1, cpvneg(n0), clear}, {v1, cpvzero, black}};
			_triangles[vert_count-2 + border_verts*i + 1] = (Triangle){{inner0, cpvneg(n0), clear}, {v0, cpvzero, black}, {v1, cpvzero, black}};
			_triangles[vert_count-2 + border_verts*i + 2] = (Triangle){{e2, n0, clear}, {v0, cpvzero, black}, {v1, cpvzero, black}};
			_triangles[vert_count-2 + border_verts*i + 3] = (Triangle){{e2, n0, clear}, {v0, cpvzero, black}, {e1, n0, clear}};
			_triangles[vert_count-2 + border_verts*i + 4] = (Triangle){{v1, cpvzero, black}, {e2, n0, clear}, {outer1, offset1, clear}};
			_triangles[vert_count-2 + border_verts*i + 5] = (Triangle){{v1, cpvzero, black}, {e3, n1, clear}, {outer1, offset1, clear}};
//			_triangles[vert_count-2 + border_verts*i + 2] = (Triangle){{outer1, n0, clear}, {v0, cpvzero, black}, {v1, cpvzero, black}};
//			_triangles[vert_count-2 + border_verts*i + 3] = (Triangle){{outer1, n0, clear}, {v0, cpvzero, black}, {outer0, n0, clear}};
		}
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, vertex));
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, texcoord));
    
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, color));
    
    glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

static inline cpFloat frand(){return (cpFloat)rand()/(cpFloat)RAND_MAX;}

#define POLY_COUNT 500

- (void)update
{
	if(self.framesDisplayed%100 == 0) NSLog(@"TPS: %f", 1.0/self.timeSinceLastUpdate);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	if(self.framesDisplayed%100 == 0) NSLog(@"FPS: %f", 1.0/self.timeSinceLastDraw);
	
	glClear(GL_COLOR_BUFFER_BIT);
	cpFloat width = [(GLKView *)self.view drawableWidth];
	cpFloat height = [(GLKView *)self.view drawableHeight];
	
	// Render the object again with ES2
	glUseProgram(_program);
	
	GLKMatrix4 mvp = GLKMatrix4MakeOrtho(0.0, width, 0.0, height, -1.0, 1.0);
	glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, mvp.m);
	glUniform1f(uniforms[UNIFORM_FWIDTH], 1.0/WIDTH);
	
	srand(97234);
	cpFloat time = self.timeSinceLastResume;
	
	int vertex_count = POLY_COUNT*_triangleCount*3;
	
	Vertex *vertex_src = (Vertex *)_triangles;
	Vertex *vertex_dst = calloc(vertex_count, sizeof(Vertex));
	Vertex *cursor = vertex_dst;
	
	for(int i=0; i<POLY_COUNT; i++){
		cpVect pos = cpv(width*frand(), height*frand());
		cpVect rot = cpvforangle((frand()*2.0 - 1.0)*time*3.0);
		
		Transform t = {
			rot.x, -rot.y, pos.x,
			rot.y,  rot.x, pos.y,
		};
		t = t_wrap(t_translate(cpv(0.0, -50.0)), t);
		
		int poly_vertex_count = _triangleCount*3;
		
		memcpy(cursor, vertex_src, poly_vertex_count*sizeof(Vertex));
#if __ARM_NEON__
		float32x2_t col0 = vld1_f32(&t.a);
		float32x2_t col1 = vld1_f32(&t.d);
		float32x2_t col2 = (float32x2_t){t.c, t.f};
		
		for(int i=0; i<poly_vertex_count; i++){
			float32x2_t *ptr = (float32x2_t *)&cursor[i].vertex;
			float32x2_t p = vld1_f32(ptr);
			float32x2_t x = vmul_f32(col0, p);
			float32x2_t y = vmul_f32(col1, p);
			vst1_f32(ptr, vadd_f32(vpadd_f32(x, y), col2));
		}
#else
		for(int i=0; i<poly_vertex_count; i++) cursor[i].vertex = t_point(t, cursor[i].vertex);
#endif
		cursor += _triangleCount*3;
	}
	
	glBindVertexArrayOES(_vertexArray);
	glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*vertex_count, vertex_dst, GL_STREAM_DRAW);
	free(vertex_dst);
	
	glDrawArrays(GL_TRIANGLES, 0, vertex_count);
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "texcoord");
    glBindAttribLocation(_program, ATTRIB_COLOR, "color");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_FWIDTH] = glGetUniformLocation(_program, "fwidth");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
