#import <Foundation/Foundation.h>

#import "PolyRenderer.h"

@interface PolyInstance : NSObject

@property(nonatomic, readonly) NSUInteger vertexCount;
@property(nonatomic, readonly) Vertex *vertexes;

-(id)initWithShape:(ChipmunkShape *)shape width:(cpFloat)width FillColor:(Color)fill lineColor:(Color)line;

@end
