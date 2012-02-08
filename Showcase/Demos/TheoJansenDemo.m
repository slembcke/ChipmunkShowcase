#import "ShowcaseDemo.h"

@interface TheoJansenDemo : ShowcaseDemo @end
@implementation TheoJansenDemo

-(NSString *)name
{
	return @"Theo Jansen Machine";
}

#define SEG_RADIUS 3.0f
static NSString *GROUP = @"group";

//static void
//make_leg(cpFloat side, cpFloat offset, cpBody *chassis, cpBody *crank, cpVect anchor)
-(void)makeLeg:(cpFloat)side offset:(cpFloat)offset chassis:(ChipmunkBody *)chassis crank:(ChipmunkBody *)crank anchor:(cpVect)anchor
{
	cpFloat leg_mass = 1.0f;
	cpVect a, b;
	
	a = cpvzero, b = cpv(0.0f, side);
	ChipmunkBody *upper_leg = [self.space add:[ChipmunkBody bodyWithMass:leg_mass andMoment:cpMomentForSegment(leg_mass, a, b)]];
	upper_leg.pos = cpv(offset, 0.0);
	
	[self.space add:[ChipmunkSegmentShape segmentWithBody:upper_leg from:a to:b radius:SEG_RADIUS]];
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:chassis bodyB:upper_leg anchr1:cpv(offset, 0) anchr2:cpvzero]];
	
	a = cpvzero, b = cpv(0.0f, -1.0f*side);
	ChipmunkBody *lower_leg = [self.space add:[ChipmunkBody bodyWithMass:leg_mass andMoment:cpMomentForSegment(leg_mass, a, b)]];
	lower_leg.pos = cpv(offset, -side);
	
	ChipmunkShape *shape;
	shape = [self.space add:[ChipmunkSegmentShape segmentWithBody:lower_leg from:a to:b radius:SEG_RADIUS]];
	shape.group = GROUP;
	
	shape = [self.space add:[ChipmunkCircleShape circleWithBody:lower_leg radius:SEG_RADIUS*2.0f offset:b]];
	shape.group = GROUP;
	shape.elasticity = 0.0;
	shape.friction = 1.0;
	
	[self.space add:[ChipmunkPinJoint pinJointWithBodyA:chassis bodyB:lower_leg anchr1:cpv(offset, 0.0f) anchr2:cpvzero]];
	[self.space add:[ChipmunkGearJoint gearJointWithBodyA:upper_leg bodyB:lower_leg phase:0.0f ratio:1.0f]];
	
	cpFloat diag = cpfsqrt(side*side + offset*offset);
	
	ChipmunkPinJoint *pin1 = [self.space add:[ChipmunkPinJoint pinJointWithBodyA:crank bodyB:upper_leg anchr1:anchor anchr2:cpv(0.0f, side)]];
	pin1.dist = diag;
	
	ChipmunkPinJoint *pin2 = [self.space add:[ChipmunkPinJoint pinJointWithBodyA:crank bodyB:lower_leg anchr1:anchor anchr2:cpvzero]];
	pin2.dist = diag;
}

-(void)setup
{
	self.space.iterations = 20;
	
	CGRect bounds = CGRectMake(-320, -240, 640, 480);
	[self.space addBounds:bounds thickness:10.0 elasticity:1.0 friction:1.0 layers:NOT_GRABABLE_MASK group:nil collisionType:nil];
	
	cpFloat offset = 30.0f;
	ChipmunkShape *shape;

	// make chassis
	cpFloat chassis_mass = 2.0f;
	cpVect a = cpv(-offset, 0.0f);
	cpVect b = cpv(offset, 0.0f);
	ChipmunkBody *chassis = [self.space add:[ChipmunkBody bodyWithMass:chassis_mass andMoment:cpMomentForSegment(chassis_mass, a, b)]];
	
	shape = [self.space add:[ChipmunkSegmentShape segmentWithBody:chassis from:a to:b radius:SEG_RADIUS]];
	shape.group = GROUP;
	
	// make crank
	cpFloat crank_mass = 1.0f;
	cpFloat crank_radius = 13.0f;
	ChipmunkBody *crank = [self.space add:[ChipmunkBody bodyWithMass:crank_mass andMoment:cpMomentForCircle(crank_mass, crank_radius, 0.0f, cpvzero)]];
	
	shape = [self.space add:[ChipmunkCircleShape circleWithBody:crank radius:crank_radius offset:cpvzero]];
	shape.group = GROUP;
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:chassis bodyB:crank anchr1:cpvzero anchr2:cpvzero]];
	
	cpFloat side = 30.0f;
	
	int num_legs = 2;
	for(int i=0; i<num_legs; i++){
		[self makeLeg:side offset: offset chassis:chassis crank:crank anchor:cpvmult(cpvforangle((cpFloat)(2*i+0)/(cpFloat)num_legs*M_PI), crank_radius)];
		[self makeLeg:side offset:-offset chassis:chassis crank:crank anchor:cpvmult(cpvforangle((cpFloat)(2*i+1)/(cpFloat)num_legs*M_PI), crank_radius)];
	}
}

-(void)tick:(cpFloat)dt;
{
	self.space.gravity = cpvmult([Accelerometer getAcceleration], 500.0);
	[super tick:dt];
}

@end
