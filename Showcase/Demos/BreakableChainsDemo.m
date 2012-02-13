#import "ShowcaseDemo.h"

@interface BreakableChainsDemo : ShowcaseDemo @end
@implementation BreakableChainsDemo

-(NSString *)name
{
	return @"Breakable Chains";
}

#define CHAIN_COUNT 8
#define LINK_COUNT 10

static void
BreakableJointPostSolve(cpConstraint *joint, cpSpace *space)
{
	cpFloat dt = cpSpaceGetCurrentTimeStep(space);
	
	// Convert the impulse to a force by dividing it by the timestep.
	cpFloat force = cpConstraintGetImpulse(joint)/dt;
	cpFloat maxForce = cpConstraintGetMaxForce(joint);

	// If the force is almost as big as the joint's max force, break it.
	if(force > 0.9*maxForce){
		[cpSpaceGetUserData(space) addPostStepRemoval:cpConstraintGetUserData(joint)];
	}
}

-(void)setup
{
	self.space.iterations = 30;
	
//	cpBody *body, *staticBody = cpSpaceGetStaticBody(space);
//	cpShape *shape;
	
	CGRect bounds = CGRectMake(-320, -240, 640, 480);
	[self.space addBounds:bounds thickness:10.0 elasticity:1.0 friction:1.0 layers:NOT_GRABABLE_MASK group:nil collisionType:nil];
	
	cpFloat mass = 1;
	cpFloat width = 20;
	cpFloat height = 30;
	
	cpFloat spacing = width*0.3;
	
	// Add lots of boxes.
	for(int i=0; i<CHAIN_COUNT; i++){
		ChipmunkBody *prev = nil;
		
		for(int j=0; j<LINK_COUNT; j++){
			cpVect pos = cpv(40*(i - (CHAIN_COUNT - 1)/2.0), 240 - (j + 0.5)*height - (j + 1)*spacing);
			
			ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, width, height)]];
			body.pos = pos;
			
			ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:width height:height]];
			shape.friction = 0.8f;
			
			ChipmunkConstraint *constraint = nil;
			if(prev == nil){
				constraint = [self.space add:[ChipmunkSlideJoint slideJointWithBodyA:body bodyB:self.space.staticBody anchr1:cpv(0, height/2) anchr2:cpv(pos.x, 240) min:0.0 max:spacing]];
			} else {
				constraint = [self.space add:[ChipmunkSlideJoint slideJointWithBodyA:body bodyB:prev anchr1:cpv(0, height/2) anchr2:cpv(0, -height/2) min:0.0 max:spacing]];
			}
			
			constraint.maxForce = 8.0e4;
			cpConstraintSetPostSolveFunc(constraint.constraint, BreakableJointPostSolve);
			
			prev = body;
		}
	}
	
	{
		cpFloat radius = 15.0f;
		cpFloat mass = 10.0;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
		body.pos = cpv(0, -240 + radius + 5);
		body.vel = cpv(0, 300);

		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
		shape.elasticity = 0.0f;
		shape.friction = 0.9f;
	}
}

-(NSTimeInterval)preferredTimeStep;
{
	return 1.0/120.0;
}

-(void)tick:(cpFloat)dt;
{
	self.space.gravity = cpvmult([Accelerometer getAcceleration], 100.0);
	[super tick:dt];
}

@end
