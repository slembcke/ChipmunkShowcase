#import <Foundation/Foundation.h>

#import "ObjectiveChipmunk.h"
#import "transform.h"

#define PRINT_GL_ERRORS() for(GLenum err = glGetError(); err; err = glGetError()) NSLog(@"GLError(%s:%d) 0x%04X", __FILE__, __LINE__, err);

typedef struct Color {GLfloat r, g, b, a;} Color;

static inline Color RGBAColor(GLfloat r, GLfloat g, GLfloat b, GLfloat a){
	return (Color){r, g, b, a};
}

static inline Color LAColor(GLfloat l, GLfloat a){
	return (Color){l, l, l, a};
}


typedef struct Vertex {cpVect vertex, texcoord; Color color;} Vertex;
typedef struct Triangle {Vertex a, b, c;} Triangle;

#import "PolyInstance.h"


@interface PolyRenderer : NSObject

@property(nonatomic, assign) Transform projection;

-(id)initWithProjection:(Transform)projection;

-(void)drawDot:(cpVect)pos radius:(cpFloat)radius color:(Color)color;
-(void)drawSegmentFrom:(cpVect)a to:(cpVect)b radius:(cpFloat)radius color:(Color)color;
-(void)drawPolyWithVerts:(cpVect *)verts count:(NSUInteger)count width:(cpFloat)width fill:(Color)fill line:(Color)line;

-(void)render;

@end
