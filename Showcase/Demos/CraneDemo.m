#import "ShowcaseDemo.h"

@interface CraneDemo : ShowcaseDemo @end
@implementation CraneDemo {
	ChipmunkBody *_dollyBody;
	// Constraint used as a servo motor to move the dolly back and forth.
	ChipmunkPivotJoint *_dollyServo;

	// Constraint used as a winch motor to lift the load.
	ChipmunkSlideJoint *_winchServo;

	// Temporary joint used to hold the hook to the load.
	ChipmunkPivotJoint *_hookJoint;
	
	cpVect _touchTarget;
}

-(NSString *)name
{
	return @"Crane";
}

static NSString *HOOK_SENSOR = @"HOOK_SENSOR";
static NSString *CRATE = @"CRATE";

-(bool)hookCrate:(cpArbiter *)arb space:(ChipmunkSpace *)space
{
	if(_hookJoint == nil){
		// Get pointers to the two bodies in the collision pair and define local variables for them.
		// Their order matches the order of the collision types passed
		// to the collision handler this function was defined for
		CHIPMUNK_ARBITER_GET_BODIES(arb, hook, crate);
		
		// additions and removals can't be done in a normal callback.
		// Schedule a post step callback to do it.
		// Use the hook as the key and pass along the arbiter.
		[space addPostStepBlock:^{
			_hookJoint = [space add:[ChipmunkPivotJoint pivotJointWithBodyA:hook bodyB:crate pivot:hook.pos]];
		} key:hook];
	}
	
	return cpTrue; // return value is ignored for sensor callbacks anyway
}


-(void)setup
{
	self.space.gravity = cpv(0, -100);
	self.space.damping = 0.8;
	
	[self.space addBounds:self.demoBounds thickness:10.0 elasticity:1.0 friction:1.0 layers:NOT_GRABABLE_MASK group:nil collisionType:nil];
	
	// Add a body for the dolly.
	_dollyBody = [self.space add:[ChipmunkBody bodyWithMass:10 andMoment:INFINITY]];
	_dollyBody.pos = cpv(0, 100);
	
	// Add a block so you can see it.
	[self.space add:[ChipmunkPolyShape boxWithBody:_dollyBody width:30 height:30]];
	
	// Add a groove joint for it to move back and forth on.
	[self.space add:[ChipmunkGrooveJoint grooveJointWithBodyA:self.space.staticBody bodyB:_dollyBody groove_a:cpv(-250, 100) groove_b:cpv(250, 100) anchr2:cpvzero]];
	
	// Add a pivot joint to act as a servo motor controlling it's position
	// By updating the anchor points of the pivot joint, you can move the dolly.
	_dollyServo = [self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:self.space.staticBody bodyB:_dollyBody pivot:_dollyBody.pos]];
	// Max force the dolly servo can generate.
	_dollyServo.maxForce = 1e4;
	// Max speed of the dolly servo
	_dollyServo.maxBias = 100;
	// You can also change the error bias to control how it slows down.
	
	
	// Add the crane hook.
	ChipmunkBody *hookBody = [self.space add:[ChipmunkBody bodyWithMass:1.0 andMoment:INFINITY]];
	hookBody.pos = cpv(0, 50);
	
	// Add a sensor shape for it. This will be used to figure out when the hook touches a box.
	ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:hookBody radius:10 offset:cpvzero]];
	shape.sensor = TRUE;
	shape.collisionType = HOOK_SENSOR;
	
	// Add a slide joint to act as a winch motor
	// By updating the max length of the joint you can make it pull up the load.
	_winchServo = [self.space add:[ChipmunkSlideJoint slideJointWithBodyA:_dollyBody bodyB:hookBody anchr1:cpvzero anchr2:cpvzero min:0 max:INFINITY]];
	// Max force the dolly servo can generate.
	_winchServo.maxForce = 3e4;
	// Max speed of the dolly servo
	_winchServo.maxBias = 60;
	
	// Finally a box to play with
	{
		cpFloat size = 50;
		cpFloat mass = 30;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, size, size)]];
		body.pos = cpv(200, -200);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:size height:size]];
		shape.friction = 0.7;
		shape.collisionType = CRATE;
	}
	
	[self.space addCollisionHandler:self typeA:HOOK_SENSOR typeB:CRATE begin:@selector(hookCrate:space:) preSolve:nil postSolve:nil separate:nil];
}

-(void)tick:(cpFloat)dt;
{
	// Set the first anchor point (the one attached to the static body) of the dolly servo to the mouse's x position.
	_dollyServo.anchr1 = cpv(_touchTarget.x, 100);
	
	// Set the max length of the winch servo to match the mouse's height.
	_winchServo.max = cpfmax(100 - _touchTarget.y, 50);
	
	[super tick:dt];
}

-(void)render:(PolyRenderer *)renderer showContacts:(BOOL)showContacts
{
	cpFloat t = cpfsin(self.renderTime*2.0*M_PI)*0.5 + 0.5;
	Color color = RGBAColor(1.0, 0.0, 0.0, cpflerp(0.25, 0.5, t));
	[renderer drawSegmentFrom:cpv(_touchTarget.x, 100.0) to:_touchTarget radius:1.0 color:color];
	
	[super render:renderer showContacts:showContacts];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	UITouch *touch = [touches anyObject];
	_touchTarget = [self convertTouch:touch];
	
	if(_hookJoint && touch.tapCount == 2){
		[self.space remove:_hookJoint];
		_hookJoint = nil;
	}
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	_touchTarget = [self convertTouch:[touches anyObject]];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
}

@end
