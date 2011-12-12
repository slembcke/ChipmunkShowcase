#import "ShowcaseDemo.h"

@interface MultiGrabDemo : ShowcaseDemo
@end


@implementation MultiGrabDemo

-(NSString *)name
{
	return @"Multi-touch Physics";
}

-(void)setup
{
	CGRect bounds = CGRectMake(-320, -240, 640, 480);
	[self.space addBounds:bounds thickness:10.0 elasticity:1.0 friction:1.0 layers:NOT_GRABABLE_MASK group:nil collisionType:nil];
	
	cpFloat mass = 50.0;
	cpFloat width = 400.0;
	cpFloat height = 150.0;
	
	ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, width, height)]];
	
	ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:width height:height]];
	shape.elasticity = 0.3;
	shape.friction = 0.7;	
}

-(void)tick:(cpFloat)dt;
{
	self.space.gravity = cpvmult([Accelerometer getAcceleration], 300.0);
	[super tick:dt];
}

@end
