#import "PolyRenderer.h"
#import "Accelerometer.h"

#define GRABABLE_MASK_BIT (1<<31)
#define NOT_GRABABLE_MASK (~GRABABLE_MASK_BIT)

@interface ShowcaseDemo : NSObject

@property(nonatomic, readonly) NSString *name;

@property(nonatomic, strong) ChipmunkSpace *space;
@property(nonatomic, readonly) ChipmunkBody *staticBody;

@property(nonatomic, assign) Transform touchTransform;

@property(nonatomic, readonly) NSTimeInterval accumulator;
@property(nonatomic, readonly) NSTimeInterval fixedDt;
@property(nonatomic, assign) cpFloat timeScale;

-(void)update:(NSTimeInterval)dt;
-(void)tick:(cpFloat)dt;

-(void)prepareStaticRenderer:(PolyRenderer *)renderer;
-(void)render:(PolyRenderer *)renderer;

@end

//MARK: Utility Methods

static inline cpFloat
frand(void)
{
	return (cpFloat)rand()/(cpFloat)RAND_MAX;
}

static cpVect
frand_unit_circle()
{
	cpVect v = cpv(frand()*2.0f - 1.0f, frand()*2.0f - 1.0f);
	return (cpvlengthsq(v) < 1.0f ? v : frand_unit_circle());
}


