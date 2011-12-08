#import <Foundation/Foundation.h>

#import "PolyRenderer.h"

#define WIDTH 1.0

@interface PolyInstance : NSObject

@property(nonatomic, readonly) NSUInteger vertexCount;
@property(nonatomic, readonly) Vertex *vertexes;

-(id)initWithShape:(ChipmunkShape *)shape FillColor:(Color)fill lineColor:(Color)line;

@end
