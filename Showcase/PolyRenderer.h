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

#import <Foundation/Foundation.h>

#import "ObjectiveChipmunk.h"
#import "transform.h"

#define PRINT_GL_ERRORS() for(GLenum err = glGetError(); err; err = glGetError()) NSLog(@"GLError(%s:%d) 0x%04X", __FILE__, __LINE__, err);

typedef struct Color {GLfloat r, g, b, a;} Color;

static inline Color RGBAColor(GLfloat r, GLfloat g, GLfloat b, GLfloat a){
	return (Color){a*r, a*g, a*b, a};
}

static inline Color LAColor(GLfloat l, GLfloat a){
	return (Color){a*l, a*l, a*l, a};
}


typedef struct Vertex {cpVect vertex, texcoord; Color color;} Vertex;
typedef struct Triangle {Vertex a, b, c;} Triangle;


@interface PolyRenderer : NSObject

@property(nonatomic, assign) Transform projection;

-(id)initWithProjection:(Transform)projection;

-(void)drawDot:(cpVect)pos radius:(cpFloat)radius color:(Color)color;
-(void)drawRing:(cpVect)pos radius:(cpFloat)radius which:(float)which;
-(void)drawSegmentFrom:(cpVect)a to:(cpVect)b radius:(cpFloat)radius color:(Color)color;
-(void)drawPolyWithVerts:(cpVect *)verts count:(NSUInteger)count width:(cpFloat)width fill:(Color)fill line:(Color)line;

-(void)render;

@end
