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
	shape.friction = 1.0;
	shape.group = SCISSOR_GROUP;
	
	return body;
}

-(void)addGripperToBody:(ChipmunkBody *)body withBB:(cpBB)bb
{
	ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body bb:bb]];
	shape.friction = 1.0;
}

-(void)setup
{
	self.space.gravity = cpv(0, -600);
	self.space.damping = 0.4;
	self.space.iterations = 20;
	
	[self.space addBounds:self.demoBounds thickness:10.0 elasticity:1.0 friction:1.0 layers:NOT_GRABABLE_MASK group:nil collisionType:nil];
	
	ChipmunkBody *scissor1 = [self addScissorAt:cpvzero angle:0.0];
	ChipmunkBody *scissor2 = [self addScissorAt:cpvzero angle:M_PI_2];
	ChipmunkBody *scissor3 = [self addScissorAt:cpv(SCALE, SCALE) angle:0.0];
	ChipmunkBody *scissor4 = [self addScissorAt:cpv(SCALE, SCALE) angle:M_PI_2];
	
	// Add handles
	cpFloat handleSize = 30.0;
	[self.space add:[ChipmunkCircleShape circleWithBody:scissor1 radius:handleSize offset:cpv(-SCALE, 0)]];
	[self.space add:[ChipmunkCircleShape circleWithBody:scissor2 radius:handleSize offset:cpv(-SCALE, 0)]];
	
	// Add grippers
	[self addGripperToBody:scissor3 withBB:cpBBNew(SCALE - THICKNESS/2.0,  THICKNESS/2.0, SCALE + THICKNESS/2.0,  SCALE/2.0)];
	[self addGripperToBody:scissor4 withBB:cpBBNew(SCALE - THICKNESS/2.0, -SCALE/2.0, SCALE + THICKNESS/2.0, -THICKNESS/2.0)];
	
	[self.space add:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:scissor1 bodyB:scissor2 min:M_PI/2.0 max:0.8*M_PI]];
	[self.space add:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:scissor3 bodyB:scissor4 min:M_PI/2.0 max:0.8*M_PI]];
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

-(NSTimeInterval)preferredTimeStep
{
	return 1.0/120.0;
}

@end
