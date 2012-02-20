#define CP_ALLOW_PRIVATE_ACCESS

#import "ShowcaseDemo.h"

#import "ObjectiveChipmunk.h"
#import "ChipmunkHastySpace.h"
#import "PolyRenderer.h"

@implementation ChipmunkBody(DemoRenderer)

-(Transform)extrapolatedTransform:(NSTimeInterval)dt
{
	cpBody *body = self.body;
	cpVect pos = cpvadd(body->p, cpvmult(body->v, dt));;
	cpVect rot = cpvforangle(body->a + body->w*dt);
	
	return (Transform){
		rot.x, -rot.y, pos.x,
		rot.y,  rot.x, pos.y,
	};
}

@end

#define SHAPE_OUTLINE_WIDTH 1.0
#define SHAPE_OUTLINE_COLOR ((Color){0.0, 0.0, 0.0, 1.0})


@interface ChipmunkShape()

-(Color)color;
-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;

@end

@implementation ChipmunkShape(DemoRenderer)

static Color
ColorFromHash(cpHashValue hash, float alpha)
{
	unsigned long val = (unsigned long)hash;
	
	// scramble the bits up using Robert Jenkins' 32 bit integer hash function
	val = (val+0x7ed55d16) + (val<<12);
	val = (val^0xc761c23c) ^ (val>>19);
	val = (val+0x165667b1) + (val<<5);
	val = (val+0xd3a2646c) ^ (val<<9);
	val = (val+0xfd7046c5) + (val<<3);
	val = (val^0xb55a4f09) ^ (val>>16);
	
	GLfloat r = (val>>0) & 0xFF;
	GLfloat g = (val>>8) & 0xFF;
	GLfloat b = (val>>16) & 0xFF;
	
	GLfloat max = MAX(MAX(r, g), b);
	GLfloat min = MIN(MIN(r, g), b);
	GLfloat coef = 1.0/(max - min);
	
	// Saturate and scale the color
	return (Color){
		(r - min)*coef,
		(g - min)*coef,
		(b - min)*coef,
		alpha
	};
}

-(Color)color
{
	// This method uses some private API to detect some states you normally shouldn't care about.
	if(self.sensor){
		return LAColor(1, 0);
	} else {
		ChipmunkBody *body = self.body;
		
		if(body.isSleeping){
			return LAColor(0.2, 1);
		} else if(body.body->node.idleTime > self.shape->space->sleepTimeThreshold) {
			return LAColor(0.66, 1);
		} else {
			return ColorFromHash(self.shape->hashid, 1.0);
		}
	}
}

@end

// TODO add optional line and fill modes?
@implementation ChipmunkCircleShape(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	cpVect offset = self.offset;
	cpFloat r1 = self.radius;
	cpFloat r2 = r1 - SHAPE_OUTLINE_WIDTH;
	
	Transform t = [self.body extrapolatedTransform:dt];
	cpVect pos = t_point(t, offset);
	cpVect end = t_point(t, cpv(offset.x, offset.y + r2));
	
	[renderer drawDot:pos radius:r1 color:SHAPE_OUTLINE_COLOR];
	if(r2 > 0.0) [renderer drawDot:pos radius:r2 color:self.color];
	[renderer drawSegmentFrom:pos to:end radius:SHAPE_OUTLINE_WIDTH color:SHAPE_OUTLINE_COLOR];
}

@end


@implementation ChipmunkSegmentShape(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	Transform t = [self.body extrapolatedTransform:dt];
	cpVect a = t_point(t, self.a);
	cpVect b = t_point(t, self.b);
	
	cpFloat r1 = self.radius;
	cpFloat r2 = r1 - SHAPE_OUTLINE_WIDTH;
	
	[renderer drawSegmentFrom:a to:b radius:r1 color:SHAPE_OUTLINE_COLOR];
	if(r2 > 0.0) [renderer drawSegmentFrom:a to:b radius:r2 color:self.color];
}

@end


@implementation ChipmunkPolyShape(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	cpPolyShape *poly = (cpPolyShape *)self.shape;
	
	cpVect *verts = poly->verts;
	NSUInteger count = poly->numVerts;
	
	Transform t = [self.body extrapolatedTransform:dt];
	cpVect tverts[count];
	for(int i=0; i<count; i++){
		tverts[i] = t_point(t, verts[i]);
	}
	
	[renderer drawPolyWithVerts:tverts count:count width:1.0 fill:self.color line:SHAPE_OUTLINE_COLOR];
}

@end


#define CONSTRAINT_DOT_RADIUS 3.0
#define CONSTRAINT_LINE_RADIUS 1.0
#define CONSTRAINT_COLOR ((Color){0.0, 0.5, 0.0, 1.0})

@interface ChipmunkConstraint()

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;

@end


@implementation ChipmunkConstraint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt {}

@end


@implementation ChipmunkPinJoint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	cpVect a = [self.bodyA local2world:self.anchr1];
	cpVect b = [self.bodyB local2world:self.anchr2];
	
	[renderer drawDot:a radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:b radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawSegmentFrom:a to:b radius:CONSTRAINT_LINE_RADIUS color:CONSTRAINT_COLOR];
}

@end


@implementation ChipmunkSlideJoint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	cpVect a = t_point([self.bodyA extrapolatedTransform:dt], self.anchr1);
	cpVect b = t_point([self.bodyB extrapolatedTransform:dt], self.anchr2);
	
	[renderer drawDot:a radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:b radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawSegmentFrom:a to:b radius:CONSTRAINT_LINE_RADIUS color:CONSTRAINT_COLOR];
}

@end


@implementation ChipmunkPivotJoint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	cpVect a = t_point([self.bodyA extrapolatedTransform:dt], self.anchr1);
	cpVect b = t_point([self.bodyB extrapolatedTransform:dt], self.anchr2);
	
	[renderer drawDot:a radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:b radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
}

@end


@implementation ChipmunkGrooveJoint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	// Hmm apparently I never made the groove joint properties...
	cpVect a = t_point([self.bodyA extrapolatedTransform:dt], cpGrooveJointGetGrooveA(self.constraint));
	cpVect b = t_point([self.bodyA extrapolatedTransform:dt], cpGrooveJointGetGrooveB(self.constraint));
	cpVect c = t_point([self.bodyB extrapolatedTransform:dt], cpGrooveJointGetAnchr2(self.constraint));
	
	[renderer drawSegmentFrom:a to:b radius:CONSTRAINT_LINE_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:c radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
}

@end

@interface ShowcaseDemo(){
	ChipmunkSpace *_space;
	
	ChipmunkMultiGrab *_multiGrab;
	
	// Convert touches to absolute coords.
	Transform _touchTransform;
	
	NSTimeInterval _accumulator;
	NSTimeInterval _fixedTime;
}

@end


@implementation ShowcaseDemo

@dynamic name;

-(BOOL)showName
{
	return TRUE;
}

@synthesize touchTransform = _touchTransform;

@synthesize space = _space;

@synthesize ticks = _ticks;
@synthesize accumulator = _accumulator;
@synthesize timeScale = _timeScale;

@synthesize timeStep = _timeStep;

-(ChipmunkBody *)staticBody
{
	return _space.staticBody;
}

-(void)setup {}

-(id)init
{
	if((self = [super init])){
		_space = [[ChipmunkHastySpace alloc] init];
		_multiGrab = [[ChipmunkMultiGrab alloc] initForSpace:self.space withSmoothing:cpfpow(0.8, 60) withGrabForce:1e5];
		_multiGrab.layers = GRABABLE_MASK_BIT;
		
		_timeScale = 1.0;
		_timeStep = self.preferredTimeStep;
		
		[self setup];
	}
	
	return self;
}

-(NSTimeInterval)preferredTimeStep;
{
	return 1.0/60.0;
}

-(void)tick:(cpFloat)dt {
	[self.space step:dt];
	_ticks++;
}

-(void)update:(NSTimeInterval)dt
{
	NSTimeInterval fixed_dt = _timeStep;
	
	_accumulator += dt*self.timeScale;
	while(_accumulator > fixed_dt){
		[self tick:fixed_dt];
		_accumulator -= fixed_dt;
		_fixedTime += fixed_dt;
	}
}

//MARK: Rendering

-(void)render:(PolyRenderer *)renderer showContacts:(BOOL)showContacts;
{
	for(ChipmunkShape *shape in _space.shapes){
		[shape drawWithRenderer:renderer dt:_accumulator];
	}
	
	for(ChipmunkConstraint *constraint in _space.constraints){
		[constraint drawWithRenderer:renderer dt:_accumulator];
	}
	
	if(showContacts){
		// This is using the private API to efficiently render the collision points.
		// Don't do this in a real game!
		cpArray *arbiters = _space.space->arbiters;
		for(int i=0; i<arbiters->num; i++){
			cpArbiter *arb = (cpArbiter*)arbiters->arr[i];
			
			for(int i=0; i<arb->numContacts; i++){
				[renderer drawDot:arb->contacts[i].p radius:2.5 color:(Color){1,0,0,1}];
			}
		}
	}
}

//MARK: Input

-(cpVect)convertTouch:(UITouch *)touch;
{
	return t_point(_touchTransform, [touch locationInView:touch.view]);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for(UITouch *touch in touches){
		[_multiGrab beginLocation:[self convertTouch:touch]];
	}
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for(UITouch *touch in touches){
		[_multiGrab updateLocation:[self convertTouch:touch]];
	}
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for(UITouch *touch in touches){
		[_multiGrab endLocation:[self convertTouch:touch]];
	}
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEnded:touches withEvent:event];
}

@end
