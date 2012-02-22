#import "PolyRenderer.h"
#import "Accelerometer.h"

@interface ChipmunkShape(DemoRenderer)

-(Color)color;

@end

#define GRABABLE_MASK_BIT (1<<31)
#define NOT_GRABABLE_MASK (~GRABABLE_MASK_BIT)

@interface ShowcaseDemo : NSObject

@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) BOOL showName;

@property(nonatomic, strong) ChipmunkSpace *space;
@property(nonatomic, readonly) ChipmunkBody *staticBody;

@property(nonatomic, assign) Transform touchTransform;

@property(nonatomic, readonly) NSUInteger ticks;
@property(nonatomic, readonly) NSTimeInterval fixedTime;
@property(nonatomic, readonly) NSTimeInterval renderTime;
@property(nonatomic, readonly) NSTimeInterval accumulator;
@property(nonatomic, assign) cpFloat timeScale;

@property(nonatomic, readonly) NSTimeInterval preferredTimeStep;
@property(nonatomic, assign) NSTimeInterval timeStep;

// Tune for CPU and iPhone/iPad
-(float)numberForA4:(float)A4 A5:(float)A5;
-(CGRect)demoBounds;

-(void)update:(NSTimeInterval)dt;
-(void)tick:(cpFloat)dt;

-(void)render:(PolyRenderer *)renderer showContacts:(BOOL)showContacts;

//Mark: Input

-(cpVect)convertTouch:(UITouch *)touch;

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

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


#define SHAPE_OUTLINE_WIDTH 1.0
#define SHAPE_OUTLINE_COLOR ((Color){200.0/255.0, 210.0/255.0, 230.0/255.0, 1.0})

#define CONTACT_COLOR ((Color){1.0, 0.0, 0.0, 1.0})

#define CONSTRAINT_DOT_RADIUS 3.0
#define CONSTRAINT_LINE_RADIUS 1.0
#define CONSTRAINT_COLOR ((Color){0.0, 0.75, 0.0, 1.0})
