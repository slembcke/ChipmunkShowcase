#import <Foundation/Foundation.h>

#import "PolyRenderer.h"

@interface PolyInstance : NSObject

@property(nonatomic, readonly) NSUInteger vertexCount;
@property(nonatomic, readonly) Vertex *vertexes;

-(id)initWithPolyShape:(ChipmunkPolyShape *)poly width:(cpFloat)width fillColor:(Color)fill lineColor:(Color)line;
-(id)initWithSegmentShape:(ChipmunkSegmentShape *)seg width:(cpFloat)width fillColor:(Color)fill lineColor:(Color)line;
-(id)initWithCircleShape:(ChipmunkCircleShape *)circle width:(cpFloat)width fillColor:(Color)fill lineColor:(Color)line;

@end
