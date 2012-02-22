#import "ShowcaseDemo.h"

@interface PyramidStackDemo : ShowcaseDemo @end
@implementation PyramidStackDemo

-(NSString *)name
{
	return @"Pyramid Stack";
}

-(void)setup
{
	self.space.gravity = cpv(0, -100.0f);
	self.space.iterations = 30;
	self.space.sleepTimeThreshold = 0.5f;
	self.space.collisionSlop = 0.5f;
	
	CGRect bounds = self.demoBounds;
	bounds.size.height = bounds.size.width;
	[self.space addBounds:bounds thickness:10.0 elasticity:1.0 friction:1.0 layers:NOT_GRABABLE_MASK group:nil collisionType:nil];
	
	NSUInteger height = [self numberForA4:14 A5:28];
	cpFloat size = [self numberForA4:28.0 A5:20.0];
	
	for(int i=0; i < height; i++){
		for(int j=0; j<=i; j++){
			cpFloat mass = 2.0;
			
			cpFloat spacing = size + 2.0;
			
			ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, size, size)]];
			body.pos = cpv((j - i/2.0)*spacing, -200 + (height - i - 1)*spacing);
			
			ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:size height:size]];
			shape.elasticity = 0.0;
			shape.friction = 0.8f;
		}
	}
	
	// Add a ball to make things more interesting
	{
		cpFloat radius = 10.0f;
		cpFloat mass = 20.0f;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
		body.pos = cpv(0, -240 + radius+5);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
		shape.elasticity = 0.0f;
		shape.friction = 0.9f;
	}
}

-(NSTimeInterval)preferredTimeStep
{
	return 1.0/60.0;
}

@end
