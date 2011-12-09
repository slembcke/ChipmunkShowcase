#import <Foundation/Foundation.h>

#import "ObjectiveChipmunk.h"
#import "transform.h"

#define PRINT_GL_ERRORS() for(GLenum err = glGetError(); err; err = glGetError()) NSLog(@"GLError(%s:%d) 0x%04X", __FILE__, __LINE__, err);

typedef struct Color {GLfloat r, g, b, a;} Color;
typedef struct Vertex {cpVect vertex, texcoord; Color color;} Vertex;
typedef struct Triangle {Vertex a, b, c;} Triangle;

#import "PolyInstance.h"


@class PolyInstance;

@interface PolyRenderer : NSObject

@property(nonatomic, assign) Transform projection;

-(void)drawPoly:(PolyInstance *)poly withTransform:(Transform)transform;
-(void)drawDot:(cpVect)pos radius:(cpFloat)radius color:(Color)color;

-(void)render;

-(void)prepareStatic;
-(void)renderStatic;

@end
