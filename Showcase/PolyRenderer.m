/* Copyright (c) 2012 Scott Lembcke and Howling Moon Software
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "PolyRenderer.h"

#import <GLKit/GLKit.h>

#import "ObjectiveChipmunk/ObjectiveChipmunk.h"

#if __ARM_NEON__
#import "arm_neon.h"
#endif

enum {
    UNIFORM_PROJECTION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    ATTRIB_COLOR,
    NUM_ATTRIBUTES
};

struct VertexBuffer {
	GLuint vao, vbo;
	Vertex *verts;
	
	GLsizei vboCapacity;
	GLsizei capacity, count;
};

#define BUFFER_COUNT 2

@implementation PolyRenderer {
	GLuint _program;
	cpTransform _projection;
	
	VertexBuffer _buffers[BUFFER_COUNT];
	NSUInteger _currentBuffer;
}

@synthesize projection = _projection;

-(void)setProjection:(cpTransform)p
{
	NSAssert([EAGLContext currentContext], @"No GL context set!");
	
	_projection = p;

	glUseProgram(_program);
	float mat[] = {
		p.a , p.b , 0.0, 0.0,
		p.c , p.d , 0.0, 0.0,
		0.0 , 0.0 , 1.0, 0.0,
    p.tx, p.ty, 0.0, 1.0,
  };
	glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION_MATRIX], 1, GL_FALSE, mat);
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
	NSAssert([EAGLContext currentContext], @"No GL context set!");
	
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
	NSAssert([EAGLContext currentContext], @"No GL context set!");
	
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

-(VertexBuffer *)buffer
{
	return (_buffers + _currentBuffer);
}

static void
EnsureCapacity(VertexBuffer *buffer, NSUInteger count)
{
	if(buffer->count + count > buffer->capacity){
		NSLog(@"VBO too small. Aborting.");
		abort();
//		buffer->capacity += MAX(buffer->capacity, count);
//		buffer->verts = realloc(buffer->verts, buffer->capacity*sizeof(Vertex));
////		NSLog(@"Resized vertex buffer to %d", _bufferCapacity);
	}
}

-(Vertex *)bufferVertexes:(NSUInteger)count
{
	VertexBuffer *buffer = self.buffer;
	EnsureCapacity(buffer, count);
	
	Vertex *verts = (buffer->verts + buffer->count);
	
	buffer->count += count;
	return verts;
}

-(id)initWithProjection:(cpTransform)projection;
{
	if((self = [super init])){
		NSAssert([EAGLContext currentContext], @"No GL context set!");
    [self loadShaders];
		
		glUseProgram(_program);
		self.projection = projection;
		
		for(int i=0; i<BUFFER_COUNT; i++){
			glGenVertexArraysOES(1, &_buffers[i].vao);
			glBindVertexArrayOES(_buffers[i].vao);
			
			_buffers[i].capacity = 128*1024;
			GLsizei buffer_bytes = _buffers[i].capacity*sizeof(Vertex);
			NSLog(@"Allocating %d buffer bytes", buffer_bytes);
			
			glGenBuffers(1, &_buffers[i].vbo);
			glBindBuffer(GL_ARRAY_BUFFER, _buffers[i].vbo);
			glBufferData(GL_ARRAY_BUFFER, buffer_bytes, NULL, GL_DYNAMIC_DRAW);
			_buffers[i].verts = glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
//			EnsureCapacity(_buffers + i, 512);
			
			glEnableVertexAttribArray(ATTRIB_VERTEX);
			glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, vertex));
			
			glEnableVertexAttribArray(ATTRIB_TEXCOORD);
			glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, texcoord));
			
			glEnableVertexAttribArray(ATTRIB_COLOR);
			glVertexAttribPointer(ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, color));
			
			glBindVertexArrayOES(0);
			PRINT_GL_ERRORS();
		}
	}
	
	return self;
}

-(void)dealloc
{
	NSAssert([EAGLContext currentContext], @"No GL context set!");
	
	for(int i=0; i<BUFFER_COUNT; i++){
//		free(_buffers[i].verts); _buffers[i].verts = 0;
		
		glDeleteProgram(_program); _program = 0;
		NSLog(@"Deleting buffer %d", _buffers[i].vbo);
		glDeleteBuffers(1, &_buffers[i].vbo); _buffers[i].vbo = 0;
		glDeleteVertexArraysOES(1, &_buffers[i].vao); _buffers[i].vao = 0;
	}
}

//MARK: Immediate Mode

-(void)drawDot:(cpVect)pos radius:(cpFloat)radius color:(Color)color;
{
	Vertex a = {{pos.x - radius, pos.y - radius}, {-1.0, -1.0}, color};
	Vertex b = {{pos.x - radius, pos.y + radius}, {-1.0,  1.0}, color};
	Vertex c = {{pos.x + radius, pos.y + radius}, { 1.0,  1.0}, color};
	Vertex d = {{pos.x + radius, pos.y - radius}, { 1.0, -1.0}, color};
	
	Triangle *triangles = (Triangle *)[self bufferVertexes:2*3];
	triangles[0] = (Triangle){a, b, c};
	triangles[1] = (Triangle){a, c, d};
}

-(void)drawSegmentFrom:(cpVect)a to:(cpVect)b radius:(cpFloat)radius color:(Color)color;
{
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
	
	Triangle *triangles = (Triangle *)[self bufferVertexes:6*3];
	triangles[0] = (Triangle){{v0, cpvneg(cpvadd(n, t)), color}, {v1, cpvsub(n, t), color}, {v2, cpvneg(n), color},};
	triangles[1] = (Triangle){{v3, n, color}, {v1, cpvsub(n, t), color}, {v2, cpvneg(n), color},};
	triangles[2] = (Triangle){{v3, n, color}, {v4, cpvneg(n), color}, {v2, cpvneg(n), color},};
	triangles[3] = (Triangle){{v3, n, color}, {v4, cpvneg(n), color}, {v5, n, color},};
	triangles[4] = (Triangle){{v6, cpvsub(t, n), color}, {v4, cpvneg(n), color}, {v5, n, color},};
	triangles[5] = (Triangle){{v6, cpvsub(t, n), color}, {v7, cpvadd(n, t), color}, {v5, n, color},};
}

-(void)drawPolyWithVerts:(cpVect *)verts count:(NSUInteger)count width:(cpFloat)width fill:(Color)fill line:(Color)line;
{
	struct ExtrudeVerts {cpVect offset, n;};
	struct ExtrudeVerts extrude[count];
	bzero(extrude, sizeof(struct ExtrudeVerts)*count);
	
	for(int i=0; i<count; i++){
		cpVect v0 = verts[(i-1+count)%count];
		cpVect v1 = verts[i];
		cpVect v2 = verts[(i+1)%count];
		
		cpVect n1 = cpvnormalize(cpvperp(cpvsub(v1, v0)));
		cpVect n2 = cpvnormalize(cpvperp(cpvsub(v2, v1)));
		
		cpVect offset = cpvmult(cpvadd(n1, n2), 1.0/(cpvdot(n1, n2) + 1.0));
		extrude[i] = (struct ExtrudeVerts){offset, n2};
	}
	
	BOOL outlined = (line.a > 0.0 && width > 0.0);
	BOOL filled = (fill.a > 0.0);
	
	NSUInteger triangle_count = 3*count - 2;
	NSUInteger vertex_count = 3*triangle_count;
	
	Triangle *triangles = (Triangle *)[self bufferVertexes:vertex_count];
	Triangle *cursor = triangles;
	
	cpFloat inset = (outlined ? 0.5 : 0.0);
	if(filled){
		for(int i=0; i<count-2; i++){
			cpVect v0 = cpvsub(verts[0  ], cpvmult(extrude[0  ].offset, inset));
			cpVect v1 = cpvsub(verts[i+1], cpvmult(extrude[i+1].offset, inset));
			cpVect v2 = cpvsub(verts[i+2], cpvmult(extrude[i+2].offset, inset));
			
			*cursor++ = (Triangle){{v0, cpvzero, fill}, {v1, cpvzero, fill}, {v2, cpvzero, fill},};
		}
	}
	
	for(int i=0; i<count; i++){
		int j = (i+1)%count;
		cpVect v0 = verts[i];
		cpVect v1 = verts[j];
		
		cpVect n0 = extrude[i].n;
		
		cpVect offset0 = extrude[i].offset;
		cpVect offset1 = extrude[j].offset;
		
		if(outlined){
			cpVect inner0 = cpvsub(v0, cpvmult(offset0, width));
			cpVect inner1 = cpvsub(v1, cpvmult(offset1, width));
			cpVect outer0 = cpvadd(v0, cpvmult(offset0, width));
			cpVect outer1 = cpvadd(v1, cpvmult(offset1, width));
			
			*cursor++ = (Triangle){{inner0, cpvneg(n0), line}, {inner1, cpvneg(n0), line}, {outer1, n0, line}};
			*cursor++ = (Triangle){{inner0, cpvneg(n0), line}, {outer0, n0, line}, {outer1, n0, line}};
		} else if(filled){
			cpVect inner0 = cpvsub(v0, cpvmult(offset0, 0.5));
			cpVect inner1 = cpvsub(v1, cpvmult(offset1, 0.5));
			cpVect outer0 = cpvadd(v0, cpvmult(offset0, 0.5));
			cpVect outer1 = cpvadd(v1, cpvmult(offset1, 0.5));
			
			*cursor++ = (Triangle){{inner0, cpvzero, fill}, {inner1, cpvzero, fill}, {outer1, n0, fill}};
			*cursor++ = (Triangle){{inner0, cpvzero, fill}, {outer0, n0, fill}, {outer1, n0, fill}};
		}
	}
	
	// Hacktastic.
	self.buffer->count += 3*(cursor - triangles) - vertex_count;
}

//MARK: Rendering

-(VertexBuffer *)buffer:(void (^)(void))block
{
	VertexBuffer *buffer = self.buffer;
	if(buffer->verts == NULL){
//		NSLog(@"Buffer not ready.");
		return NULL;
	}
	
	// Buffer the draw calls.
	block();
	
	// invalidate the buffer pointer
	buffer->verts = NULL;
	
	// Switch to the next buffer.
	_currentBuffer = (_currentBuffer + 1)%BUFFER_COUNT;
	return buffer;
}

-(void)execute:(VertexBuffer *)buffer
{
	NSAssert([EAGLContext currentContext], @"No GL context set!");
	
	glBindBuffer(GL_ARRAY_BUFFER, buffer->vbo);
	glUnmapBufferOES(GL_ARRAY_BUFFER);
		
	glUseProgram(_program);
	glBindVertexArrayOES(buffer->vao);
	glDrawArrays(GL_TRIANGLES, 0, buffer->count);
		
	buffer->count = 0;
	buffer->verts = glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
	PRINT_GL_ERRORS();
}

@end
