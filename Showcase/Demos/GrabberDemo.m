#import "ShowcaseDemo.h"

@interface GrabberDemo : ShowcaseDemo @end
@implementation GrabberDemo

-(NSString *)name
{
	return @"Grabber";
}

// Wasn't sure how big to make it at first.
#define SCALE 100.0
#define THICKNESS 10.0

NSString *SCISSOR_GROUP = @"SCISSOR_GROUP";

-(ChipmunkBody *)addScissorAt:(cpVect)pos angle:(cpFloat)angle
{
	cpFloat mass = 5.0;
	cpFloat moment = cpMomentForBox(mass, 2.0*SCALE + THICKNESS, THICKNESS);
	ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:moment]];
	body.pos = pos;
	body.angle = angle;
	
	ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:2.0*SCALE + THICKNESS height:THICKNESS]];
	shape.group = SCISSOR_GROUP;
	
	return body;
}

-(void)setup
{
	self.space.damping = 0.4;
	
	CGRect bounds = CGRectMake(-320, -240, 640, 480);
	[self.space addBounds:bounds thickness:10.0 elasticity:1.0 friction:1.0 layers:NOT_GRABABLE_MASK group:nil collisionType:nil];
	
	ChipmunkBody *scissor1 = [self addScissorAt:cpvzero angle:0.0];
	ChipmunkBody *scissor2 = [self addScissorAt:cpvzero angle:M_PI_2];
	ChipmunkBody *scissor3 = [self addScissorAt:cpv(SCALE, SCALE) angle:0.0];
	ChipmunkBody *scissor4 = [self addScissorAt:cpv(SCALE, SCALE) angle:M_PI_2];
	
	// Add handles
	cpFloat handleSize = 30.0;
	[self.space add:[ChipmunkCircleShape circleWithBody:scissor1 radius:handleSize offset:cpv(-SCALE, 0)]];
	[self.space add:[ChipmunkCircleShape circleWithBody:scissor2 radius:handleSize offset:cpv(-SCALE, 0)]];
	
	// Add grippers
	[self.space add:[ChipmunkPolyShape boxWithBody:scissor3 bb:cpBBNew(SCALE - THICKNESS/2.0, THICKNESS/2.0, SCALE + THICKNESS/2.0, SCALE/2.0)]];
	[self.space add:[ChipmunkPolyShape boxWithBody:scissor4 bb:cpBBNew(SCALE - THICKNESS/2.0, -SCALE/2.0, SCALE + THICKNESS/2.0, -THICKNESS/2.0)]];
	
	[self.space add:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:scissor1 bodyB:scissor2 min:1.1 max:0.9*M_PI]];
	[self.space add:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:scissor3 bodyB:scissor4 min:1.1 max:0.9*M_PI]];
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:scissor1 bodyB:scissor2 pivot:scissor1.pos]];
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:scissor3 bodyB:scissor4 pivot:scissor3.pos]];
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:scissor1 bodyB:scissor4 pivot:cpv(SCALE, 0)]];
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:scissor2 bodyB:scissor3 pivot:cpv(0, SCALE)]];
	
	{
		cpFloat size = SCALE - THICKNESS;
		cpFloat mass = 10.0f;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, size, size)]];
		body.pos = cpv(-200, 0);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:size height:size]];
		shape.elasticity = 0.0f;
		shape.friction = 0.9f;
	}
}

-(NSTimeInterval)fixedDt;
{
	return 1.0/120.0;
}

@end
