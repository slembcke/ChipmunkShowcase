#import "ShowcaseDemo.h"

@interface MultiGrabDemo : ShowcaseDemo @end
@implementation MultiGrabDemo

-(NSString *)name
{
	return @"Multi-touch Physics";
}

-(void)setup
{
	[self.space addBounds:self.demoBounds thickness:10.0 elasticity:1.0 friction:1.0 layers:NOT_GRABABLE_MASK group:nil collisionType:nil];
	
	{
		cpFloat mass = 10.0;
		cpFloat width = 400.0;
		cpFloat height = 150.0;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, width, height)]];
		body.pos = cpv(0, 100);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:width height:height]];
		shape.elasticity = 0.3;
		shape.friction = 0.7;
	}
	
	{
		cpFloat mass = 5.0;
		cpFloat radius = 75.0;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
		body.pos = cpv(0, -100);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
		shape.elasticity = 0.3;
		shape.friction = 0.7;
	}
}

-(void)tick:(cpFloat)dt;
{
	self.space.gravity = cpvmult([Accelerometer getAcceleration], 300.0);
	[super tick:dt];
}

@end
