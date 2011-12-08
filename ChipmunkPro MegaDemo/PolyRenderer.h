#import <Foundation/Foundation.h>

#import "ObjectiveChipmunk.h"
#import "transform.h"

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

@end
