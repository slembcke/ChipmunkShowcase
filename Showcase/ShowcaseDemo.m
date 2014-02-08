/* Copyright (c) 2012 Scott Lembcke and Howling Moon Software
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import <sys/utsname.h>

#define CP_ALLOW_PRIVATE_ACCESS

#import "ShowcaseDemo.h"

#import "ObjectiveChipmunk/ObjectiveChipmunk.h"
#import "ChipmunkHastySpace.h"
#import "PolyRenderer.h"

@interface ChipmunkSpace()
- (id)initWithSpace:(cpSpace *)space;
@end

@implementation ChipmunkBody(DemoRenderer)

-(cpTransform)extrapolatedTransform:(NSTimeInterval)dt
{
	cpBody *body = self.body;
	cpVect pos = cpvadd(body->p, cpvmult(body->v, dt));;
	cpVect rot = cpvforangle(body->a + body->w*dt);
	
	return cpTransformNewTranspose(
		rot.x, -rot.y, pos.x,
		rot.y,  rot.x, pos.y
	);
}

@end


@interface ChipmunkShape()

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
	GLfloat intensity = 0.75;
	
	// Saturate and scale the color
	if(min == max){
		return RGBAColor(intensity, 0.0, 0.0, alpha);
	} else {
		GLfloat coef = alpha*intensity/(max - min);
		return (Color){
			(r - min)*coef,
			(g - min)*coef,
			(b - min)*coef,
			alpha
		};
	}
}

-(Color)color
{
	// This method uses some private API to detect some states you normally shouldn't care about.
	if(self.sensor){
		return LAColor(0.0, 0.0);
	} else {
		ChipmunkBody *body = self.body;
		
		if(body.type == CP_BODY_TYPE_STATIC || body.isSleeping){
			return LAColor(0.5, 1.0);
		} else if(body.body->sleeping.idleTime > self.space.sleepTimeThreshold) {
			return LAColor(0.33, 1.0);
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
	cpFloat r1 = MAX(self.radius, SHAPE_OUTLINE_WIDTH);
	cpFloat r2 = r1 - SHAPE_OUTLINE_WIDTH;
	
	cpTransform t = [self.body extrapolatedTransform:dt];
	cpVect pos = cpTransformPoint(t, offset);
	cpVect end = cpTransformPoint(t, cpv(offset.x, offset.y + r2));
	
	[renderer drawDot:pos radius:r1 color:SHAPE_OUTLINE_COLOR];
	if(r2 > 0.0) [renderer drawDot:pos radius:r2 color:self.color];
	[renderer drawSegmentFrom:pos to:end radius:SHAPE_OUTLINE_WIDTH color:SHAPE_OUTLINE_COLOR];
}

@end


@implementation ChipmunkSegmentShape(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	cpTransform t = [self.body extrapolatedTransform:dt];
	cpVect a = cpTransformPoint(t, self.a);
	cpVect b = cpTransformPoint(t, self.b);
	
	cpFloat r1 = MAX(self.radius, SHAPE_OUTLINE_WIDTH);
	cpFloat r2 = r1 - SHAPE_OUTLINE_WIDTH;
	
	[renderer drawSegmentFrom:a to:b radius:r1 color:SHAPE_OUTLINE_COLOR];
	if(r2 > 0.0) [renderer drawSegmentFrom:a to:b radius:r2 color:self.color];
}

@end


@implementation ChipmunkPolyShape(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	cpPolyShape *poly = (cpPolyShape *)self.shape;
	
	NSUInteger count = poly->count;
	struct cpSplittingPlane *planes = poly->planes + count;
	
	cpTransform t = [self.body extrapolatedTransform:dt];
	cpVect tverts[count];
	for(int i=0; i<count; i++){
		tverts[i] = cpTransformPoint(t, planes[i].v0);
	}
	
	[renderer drawPolyWithVerts:tverts count:count width:1.0 fill:self.color line:SHAPE_OUTLINE_COLOR];
}

@end


@interface ChipmunkConstraint()

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;

@end


@implementation ChipmunkConstraint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt {}

@end


@implementation ChipmunkPinJoint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	cpVect a = [self.bodyA localToWorld:self.anchorA];
	cpVect b = [self.bodyB localToWorld:self.anchorB];
	
	[renderer drawDot:a radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:b radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawSegmentFrom:a to:b radius:CONSTRAINT_LINE_RADIUS color:CONSTRAINT_COLOR];
}

@end


@implementation ChipmunkSlideJoint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	cpVect a = cpTransformPoint([self.bodyA extrapolatedTransform:dt], self.anchorA);
	cpVect b = cpTransformPoint([self.bodyB extrapolatedTransform:dt], self.anchorB);
	
	[renderer drawDot:a radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:b radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawSegmentFrom:a to:b radius:CONSTRAINT_LINE_RADIUS color:CONSTRAINT_COLOR];
}

@end


@implementation ChipmunkPivotJoint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	cpVect a = cpTransformPoint([self.bodyA extrapolatedTransform:dt], self.anchorA);
	cpVect b = cpTransformPoint([self.bodyB extrapolatedTransform:dt], self.anchorB);
	
	[renderer drawDot:a radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:b radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
}

@end


@implementation ChipmunkGrooveJoint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	// Hmm apparently I never made the groove joint properties...
	cpVect a = cpTransformPoint([self.bodyA extrapolatedTransform:dt], self.grooveA);
	cpVect b = cpTransformPoint([self.bodyA extrapolatedTransform:dt], self.grooveB);
	cpVect c = cpTransformPoint([self.bodyB extrapolatedTransform:dt], self.anchorB);
	
	[renderer drawSegmentFrom:a to:b radius:CONSTRAINT_LINE_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:c radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
}

@end


@implementation ChipmunkDampedSpring(DemoRenderer)

static const cpVect SPRING_VERTS[] = {
	{0.00f, 0.0f},
	{0.20f, 0.0f},
	{0.25f, 3.0f},
	{0.30f,-6.0f},
	{0.35f, 6.0f},
	{0.40f,-6.0f},
	{0.45f, 6.0f},
	{0.50f,-6.0f},
	{0.55f, 6.0f},
	{0.60f,-6.0f},
	{0.65f, 6.0f},
	{0.70f,-3.0f},
	{0.75f, 6.0f},
	{0.80f, 0.0f},
	{1.00f, 0.0f},
};
static const int SPRING_COUNT = sizeof(SPRING_VERTS)/sizeof(cpVect);

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	cpVect a = cpTransformPoint([self.bodyA extrapolatedTransform:dt], self.anchorA);
	cpVect b = cpTransformPoint([self.bodyB extrapolatedTransform:dt], self.anchorB);
	cpTransform t = cpTransformMult(cpTransformBoneScale(a, b), cpTransformScale(1.0, 1.0/cpvdist(a, b)));
	
	cpVect verts[SPRING_COUNT];
	for(int i=0; i<SPRING_COUNT; i++){
		verts[i] = cpTransformPoint(t, SPRING_VERTS[i]);
	}
	
	for(int i=1; i<SPRING_COUNT; i++){
		[renderer drawSegmentFrom:verts[i-1] to:verts[i] radius:CONSTRAINT_LINE_RADIUS color:CONSTRAINT_COLOR];
	}
	
	[renderer drawDot:a radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:b radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
}

@end

@interface ShowcaseDemo(){
	ChipmunkHastySpace *_space;
	
	ChipmunkMultiGrab *_multiGrab;
	
	// Convert touches to absolute coords.
	cpTransform _touchTransform;
	
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
@synthesize fixedTime = _fixedTime;
@synthesize accumulator = _accumulator;
@synthesize timeScale = _timeScale;

@synthesize timeStep = _timeStep;

-(NSTimeInterval)renderTime
{
	return _fixedTime + _accumulator;
}

-(ChipmunkBody *)staticBody
{
	return _space.staticBody;
}

-(float)numberForA4:(float)A4 A5:(float)A5 A6:(float)A6;
{
	struct utsname platform;
	int rc = uname(&platform);
	if(rc == -1) return A4;
	
	NSString *desc = @(platform.machine);
	if([desc compare:@"iPad2"] < 0){
		return A4;
	} else if([desc compare:@"iPad4"] < 0){
		return A5;
	} else if([desc compare:@"iPhone"] < 0){
		return A6;
	} else if([desc compare:@"iPhone3"] < 0){
		return A4;
	} else if([desc compare:@"iPhone4"] < 0){
		return A5;
	} else if([desc compare:@"x86_64"] < 0){
		return A6;
	} else {
		return A4;
	}
}

-(cpBB)demoBounds
{
	CGSize size = [UIScreen mainScreen].bounds.size;
	cpFloat width = size.height*480.0/size.width;
	
	cpFloat l = -width/2.0;
	cpFloat b = -240;
	cpFloat r = l + width;
	cpFloat t = b + 480;
	
	return cpBBNew(l, b, r, t);
}

-(void)setup {}

-(Class)spaceClass
{
	return [ChipmunkHastySpace class];
}

-(id)init
{
	if((self = [super init])){
//		_space = [[ChipmunkSpace alloc] initWithSpace:cpSpaceNew()];
		_space = [[self.spaceClass alloc] init];
		// On iOS and OS X, 0 threads will automatically select the number of threads to use.
		_space.threads = 0;
		
		NSLog(@"cpHastySpace solver running on %lu threads.", (unsigned long)_space.threads);
		
		cpFloat grabForce = 1e5;
		_multiGrab = [[ChipmunkMultiGrab alloc] initForSpace:self.space withSmoothing:cpfpow(0.3, 60) withGrabForce:grabForce];
		_multiGrab.filter = cpShapeFilterNew(CP_NO_GROUP, GRABABLE_MASK_BIT, GRABABLE_MASK_BIT);
		_multiGrab.grabFriction = grabForce*0.1;
		_multiGrab.grabRotaryFriction = 1e3;
		_multiGrab.grabRadius = 20.0;
		_multiGrab.pushMass = 1.0;
		_multiGrab.pushFriction = 0.7;
		_multiGrab.pushMode = TRUE;
		
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
		if(!shape.sensor) [shape drawWithRenderer:renderer dt:_accumulator];
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
			cpVect n = arb->n;
			
			for(int i=0; i<arb->count; i++){
				cpVect p1 = cpvadd(arb->body_a->p, arb->contacts[i].r1);
				cpVect p2 = cpvadd(arb->body_b->p, arb->contacts[i].r2);
				
				cpFloat d = 2.0f;
				cpVect a = cpvadd(p1, cpvmult(n, -d));
				cpVect b = cpvadd(p2, cpvmult(n,  d));
				
				[renderer drawSegmentFrom:a to:b radius:1.0 color:CONTACT_COLOR];
			}
		}
	}
}

//MARK: Input

-(cpVect)convertTouch:(UITouch *)touch;
{
	CGPoint p = [touch locationInView:touch.view];
	return cpTransformPoint(_touchTransform, cpv(p.x, p.y));
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
