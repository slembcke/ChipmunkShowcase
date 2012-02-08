#import "ShowcaseDemo.h"

@interface PyramidStackDemo : ShowcaseDemo @end
@implementation PyramidStackDemo

-(NSString *)name
{
	return @"Pyramid Stack";
}

-(void)setup
{
	self.space.iterations = 30;
	self.space.gravity = cpv(0, -100.0f);
	self.space.sleepTimeThreshold = 0.5f;
	self.space.collisionSlop = 0.5f;
	
	CGRect bounds = CGRectMake(-320, -240, 640, 480);
	[self.space addBounds:bounds thickness:10.0 elasticity:1.0 friction:1.0 layers:NOT_GRABABLE_MASK group:nil collisionType:nil];
	
	for(int i=0; i<14; i++){
		for(int j=0; j<=i; j++){
			cpFloat size = 30.0;
			cpFloat mass = 5.0;
			
			ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, size, size)]];
			body.pos = cpv(j*32 - i*16, 220 - i*32);
			
			ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:size height:size]];
			shape.elasticity = 0.0;
			shape.friction = 0.8f;
		}
	}
	
	// Add a ball to make things more interesting
	{
		cpFloat radius = 15.0f;
		cpFloat mass = 30.0f;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
		body.pos = cpv(0, -240 + radius+5);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
		shape.elasticity = 0.0f;
		shape.friction = 0.9f;
	}
}

-(NSTimeInterval)fixedDt;
{
	return 1.0/180.0;
}

@end
