#import "PolyRenderer.h"
#import "PolyInstance.h"

#import <GLKit/GLKit.h>

#import "ObjectiveChipmunk.h"
#import "transform.h"

#if __ARM_NEON__
#import "arm_neon.h"
#endif

enum {
    UNIFORM_PROJECTION_MATRIX,
//		UNIFORM_TEXTURE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    ATTRIB_COLOR,
    NUM_ATTRIBUTES
};

@interface PolyRenderer(){
	GLuint _program;
//	GLuint _texture;

	GLuint _vao;
	GLuint _vbo;
	
	NSUInteger _bufferCapacity, _bufferCount;
	Vertex *_buffer;
	
	Transform _projection;
}

@end


@implementation PolyRenderer

@synthesize projection = _projection;

-(void)setProjection:(Transform)projection
{
	_projection = projection;
	
	glUseProgram(_program);
	Matrix mat = t_matrix(_projection);
	glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION_MATRIX], 1, GL_FALSE, mat.m);
}

//MARK: Shaders

// TODO get rid of this gross shader loading code code
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

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"AntialiasedShader.vsh" ofType:nil];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"AntialiasedShader.fsh" ofType:nil];
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
    uniforms[UNIFORM_PROJECTION_MATRIX] = glGetUniformLocation(_program, "projection");
//    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(_program, "texture");
    
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

//MARK: Memory

-(void)ensureCapacity:(NSUInteger)count
{
	if(_bufferCount + count > _bufferCapacity){
		_bufferCapacity += MAX(_bufferCapacity, count);
		_buffer = realloc(_buffer, _bufferCapacity*sizeof(Vertex));
		
		glBindBuffer(GL_ARRAY_BUFFER, _vbo);
		glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*_bufferCapacity, NULL, GL_STREAM_DRAW);
		
		PRINT_GL_ERRORS();
//		NSLog(@"Resized vertex buffer to %d", _bufferCapacity);
	}
}

-(id)initWithProjection:(Transform)projection;
{
	if((self = [super init])){
    [self loadShaders];
		
		glUseProgram(_program);
		self.projection = projection;
		
//		glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
		
//		NSURL *texture_url = [[NSBundle mainBundle] URLForResource:@"gradient.png" withExtension:nil];
//		
//		NSError *error = nil;
//		GLKTextureInfo *tex_info = [GLKTextureLoader textureWithContentsOfURL:texture_url
//			options:[NSDictionary dictionaryWithObjectsAndKeys:
//				[NSNumber numberWithBool:TRUE], GLKTextureLoaderGenerateMipmaps,
//				[NSNumber numberWithBool:TRUE], GLKTextureLoaderOriginBottomLeft,
//				[NSNumber numberWithBool:TRUE], GLKTextureLoaderGrayscaleAsAlpha,
//				nil]
//			error:&error
//		];
//		
//		if(error){
//			NSLog(@"%@", error);
//		}
//		
//		_texture = tex_info.name;
//		glBindTexture(GL_TEXTURE_2D, _texture);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glGenVertexArraysOES(1, &_vao);
    glBindVertexArrayOES(_vao);
		
    glGenBuffers(1, &_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
		[self ensureCapacity:512];
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, vertex));
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, texcoord));
    
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, color));
    
    glBindVertexArrayOES(0);
		PRINT_GL_ERRORS();
	}
	
	return self;
}

-(void)dealloc
{
	free(_buffer); _buffer = 0;
	
	glDeleteProgram(_program); _program = 0;
//	glDeleteTextures(1, &_texture); _texture = 0;
	glDeleteBuffers(1, &_vbo); _vbo = 0;
	glDeleteVertexArraysOES(1, &_vao); _vao = 0;
}

//MARK: Immediate Mode

-(void)drawPoly:(PolyInstance *)poly withTransform:(Transform)transform;
{
	NSUInteger vertex_count = poly.vertexCount;
	[self ensureCapacity:vertex_count];
	
	Vertex *vertex_src = poly.vertexes;
	Vertex *vertex_dst = _buffer + _bufferCount;
	
	memcpy(vertex_dst, vertex_src, vertex_count*sizeof(Vertex));
#if __ARM_NEON__
	float32x2_t tx = vld1_f32(&transform.a);
	float32x2_t ty = vld1_f32(&transform.d);
	float32x2_t tcol2 = {transform.c, transform.f};
	
	for(int i=0; i<vertex_count; i++){
		float32x2_t *ptr = (float32x2_t *)&vertex_dst[i].vertex;
		float32x2_t p = vld1_f32(ptr);
		vst1_f32(ptr, vadd_f32(vpadd_f32(vmul_f32(tx, p), vmul_f32(ty, p)), tcol2));
	}
#else
	for(int i=0; i<vertex_count; i++) vertex_dst[i].vertex = t_point(transform, vertex_dst[i].vertex);
#endif
	
	_bufferCount += vertex_count;
}

-(void)drawDot:(cpVect)pos radius:(cpFloat)radius color:(Color)color;
{
	NSUInteger vertex_count = 2*3;
	[self ensureCapacity:vertex_count];
	
	Vertex a = {{pos.x - radius, pos.y - radius}, {-1.0, -1.0}, color};
	Vertex b = {{pos.x - radius, pos.y + radius}, {-1.0,  1.0}, color};
	Vertex c = {{pos.x + radius, pos.y + radius}, { 1.0,  1.0}, color};
	Vertex d = {{pos.x + radius, pos.y - radius}, { 1.0, -1.0}, color};
	
	Triangle *triangles = (Triangle *)(_buffer + _bufferCount);
	triangles[0] = (Triangle){a, b, c};
	triangles[1] = (Triangle){a, c, d};
	
	_bufferCount += vertex_count;
}

-(void)drawSegmentFrom:(cpVect)a to:(cpVect)b radius:(cpFloat)radius color:(Color)color;
{
	NSUInteger vertex_count = 6*3;
	[self ensureCapacity:vertex_count];
	
	cpVect n = cpvnormalize(cpvperp(cpvsub(b, a)));
	cpVect t = cpvperp(n);
	
	cpVect nw = cpvmult(n, radius);
	cpVect tw = cpvmult(t, radius);
	cpVect v0 = cpvsub(b, cpvadd(nw, tw));
	cpVect v1 = cpvadd(b, cpvsub(nw, tw));
	cpVect v2 = cpvsub(b, nw);
	cpVect v3 = cpvadd(b, nw);
	cpVect v4 = cpvsub(a, nw);
	cpVect v5 = cpvadd(a, nw);
	cpVect v6 = cpvsub(a, cpvsub(nw, tw));
	cpVect v7 = cpvadd(a, cpvadd(nw, tw));
	
	Triangle *triangles = (Triangle *)(_buffer + _bufferCount);
	triangles[0] = (Triangle){{v0, cpvneg(cpvadd(n, t)), color}, {v1, cpvsub(n, t), color}, {v2, cpvneg(n), color},};
	triangles[1] = (Triangle){{v3, n, color}, {v1, cpvsub(n, t), color}, {v2, cpvneg(n), color},};
	triangles[2] = (Triangle){{v3, n, color}, {v4, cpvneg(n), color}, {v2, cpvneg(n), color},};
	triangles[3] = (Triangle){{v3, n, color}, {v4, cpvneg(n), color}, {v5, n, color},};
	triangles[4] = (Triangle){{v6, cpvsub(t, n), color}, {v4, cpvneg(n), color}, {v5, n, color},};
	triangles[5] = (Triangle){{v6, cpvsub(t, n), color}, {v7, cpvadd(n, t), color}, {v5, n, color},};
	
	_bufferCount += vertex_count;
}

//MARK: Rendering

-(void)render
{
	glBindBuffer(GL_ARRAY_BUFFER, _vbo);
	glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(Vertex)*_bufferCount, _buffer);
		
//	glActiveTexture(GL_TEXTURE0);
//	glBindTexture(GL_TEXTURE_2D, _texture);
	
	glUseProgram(_program);
	glBindVertexArrayOES(_vao);
	glDrawArrays(GL_TRIANGLES, 0, _bufferCount);
	
	_bufferCount = 0;
	PRINT_GL_ERRORS();
}

// TODO make a second VBO on a renderer instead of separate ones?
-(void)prepareStatic;
{
	glBindBuffer(GL_ARRAY_BUFFER, _vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*_bufferCount, _buffer, GL_STATIC_DRAW);
	PRINT_GL_ERRORS();
}

-(void)renderStatic;
{
//	glActiveTexture(GL_TEXTURE0);
//	glBindTexture(GL_TEXTURE_2D, _texture);
	
	glUseProgram(_program);
	glBindVertexArrayOES(_vao);
	glDrawArrays(GL_TRIANGLES, 0, _bufferCount);
	PRINT_GL_ERRORS();
}

@end
