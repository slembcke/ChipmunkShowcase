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

//GLfloat gCubeVertexData[] = {
//    512.0, 512.0,
//    256.0, 512.0,
//    512.0, 256.0,
//    512.0, 256.0,
//    256.0, 512.0,
//    256.0, 256.0,
//};

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
		Color clear = {0.0, 0.0, 0.0, 0.0};
		
		int vert_count = 6;
		cpVect verts[vert_count];
		for(int i=0; i<vert_count; i++){
			cpFloat angle = -2*M_PI*i/((cpFloat)vert_count);
			verts[i] = cpv(10*cos(angle), 10*sin(angle));
		}
		
		struct ExtrudeVerts {cpVect inner, outer, n1, n2;};
		struct ExtrudeVerts extrude[vert_count];
		bzero(extrude, sizeof(struct ExtrudeVerts)*vert_count);
		
		for(int i=0; i<vert_count; i++){
			cpVect v0 = verts[(i-1+vert_count)%vert_count];
			cpVect v1 = verts[i];
			cpVect v2 = verts[(i+1)%vert_count];
			
			cpVect n1 = cpvnormalize(cpvperp(cpvsub(v1, v0)));
			cpVect n2 = cpvnormalize(cpvperp(cpvsub(v2, v1)));
			
			cpFloat r = 1.0;
			cpVect offset = cpvmult(cpvadd(n1, n2), r/(cpvdot(n1, n2) + 1.0));
			extrude[i] = (struct ExtrudeVerts){
				cpvsub(v1, offset),
				cpvadd(v1, offset),
				cpvadd(v1, cpvmult(n1, r)),
				cpvadd(v1, cpvmult(n2, r)),
			};
		}
		
		_triangleCount = (vert_count - 2) + 6*vert_count;
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
			cpVect inner0 = extrude[i].inner;
			cpVect inner1 = extrude[j].inner;
			cpVect outer1 = extrude[j].outer;
			cpVect n1 = extrude[i].n2;
			cpVect n2 = extrude[j].n1;
			cpVect n3 = extrude[j].n2;
			
			_triangles[vert_count-2 + 6*i + 0] = (Triangle){{inner0, cpvzero, clear}, {inner1, cpvzero, clear}, {v1, cpvzero, black}};
			_triangles[vert_count-2 + 6*i + 1] = (Triangle){{inner0, cpvzero, clear}, {v0, cpvzero, black}, {v1, cpvzero, black}};
			_triangles[vert_count-2 + 6*i + 2] = (Triangle){{n2, cpvzero, clear}, {v0, cpvzero, black}, {v1, cpvzero, black}};
			_triangles[vert_count-2 + 6*i + 3] = (Triangle){{n2, cpvzero, clear}, {v0, cpvzero, black}, {n1, cpvzero, clear}};
			_triangles[vert_count-2 + 6*i + 4] = (Triangle){{v1, cpvzero, black}, {n2, cpvzero, clear}, {outer1, cpvzero, clear}};
			_triangles[vert_count-2 + 6*i + 5] = (Triangle){{v1, cpvzero, black}, {n3, cpvzero, clear}, {outer1, cpvzero, clear}};
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

- (void)update
{
	// TODO transform geometry here.
}

static inline cpFloat frand(){return (cpFloat)rand()/(cpFloat)RAND_MAX;}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClear(GL_COLOR_BUFFER_BIT);
		
		int poly_count = 1000;
		int vertex_count = poly_count*_triangleCount*3;
		
		Vertex *vertex_src = (Vertex *)_triangles;
		Vertex *vertex_dst = calloc(vertex_count, sizeof(Vertex));
		Vertex *cursor = vertex_dst;
		
		for(int i=0; i<poly_count; i++){
			cpVect pos = cpv(1024.0*frand(), 768.0*frand());
			cpVect rot = cpvforangle(frand()*M_PI*2.0);
			
			Transform t = {
				rot.x, -rot.y, pos.x,
				rot.y,  rot.x, pos.y,
			};
			
			int poly_vertex_count = _triangleCount*3;
			
			memcpy(cursor, vertex_src, poly_vertex_count*sizeof(Vertex));
			for(int i=0; i<poly_vertex_count; i++){
#if __ARM_NEON__
				float32x2_t *ptr = (float32x2_t *)&cursor[i].vertex;
				float32x2_t p = vld1_f32(ptr);
				float32x2_t x = vmul_f32((float32x2_t){t.a, t.b}, p);
				float32x2_t y = vmul_f32((float32x2_t){t.d, t.e}, p);
				vst1_f32(ptr, vadd_f32(vpadd_f32(x, y), (float32x2_t){t.c, t.f}));
#else
				cursor[i].vertex = t_point(t, cursor[i].vertex);
#endif
			}
			cursor += _triangleCount*3;
		}
    
    glBindVertexArrayOES(_vertexArray);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*vertex_count, vertex_dst, GL_STREAM_DRAW);
		free(vertex_dst);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
		GLKMatrix4 mvp = GLKMatrix4MakeOrtho(0.0, 1024.0, 0.0, 768.0, -1.0, 1.0);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, mvp.m);
    
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
