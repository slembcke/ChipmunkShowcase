#import "PolyRenderer.h"
#import "Accelerometer.h"

#define GRABABLE_MASK_BIT (1<<31)
#define NOT_GRABABLE_MASK (~GRABABLE_MASK_BIT)

@interface ShowcaseDemo : NSObject

@property(nonatomic, readonly) ChipmunkSpace *space;
@property(nonatomic, readonly) ChipmunkBody *staticBody;

@property(nonatomic, assign) Transform touchTransform;

@property(nonatomic, readonly) NSTimeInterval fixedDt;

-(void)update:(NSTimeInterval)dt;
-(void)tick:(cpFloat)dt;

-(void)prepareStaticRenderer:(PolyRenderer *)renderer;
-(void)render:(PolyRenderer *)renderer timeSinceLastUpdate:(NSTimeInterval)timeSinceLastUpdate;

@end
