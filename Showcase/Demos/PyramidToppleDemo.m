#import "ShowcaseDemo.h"

@interface PyramidToppleDemo : ShowcaseDemo @end
@implementation PyramidToppleDemo

-(NSString *)name
{
	return @"Pyramid Topple";
}

#define WIDTH 5.0f
#define HEIGHT 30.0f

-(void)addDomino:(cpVect)pos flipped:(bool)flipped
{
	cpFloat mass = 1.0f;
	ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, WIDTH, HEIGHT)]];
	body.pos = pos;
	
	
	ChipmunkShape *shape = (flipped ? [ChipmunkPolyShape boxWithBody:body width:HEIGHT height:WIDTH] : [ChipmunkPolyShape boxWithBody:body width:WIDTH height:HEIGHT]);
	[self.space add:shape];
	shape.elasticity = 0.0f;
	shape.friction = 0.6f;
}

-(void)setup
{
	self.space.iterations = [self numberForA4:15 A5:20];
	self.space.gravity = cpv(0, -300.0);
	self.space.sleepTimeThreshold = 0.5f;
	self.space.collisionSlop = 0.5f;
	
	// Add a floor.
	ChipmunkShape *shape = [self.space add:[ChipmunkSegmentShape segmentWithBody:self.space.staticBody from:cpv(-600, -240) to:cpv(600, -240) radius:0]];
	shape.elasticity = 1.0;
	shape.friction = 1.0;
	shape.layers = NOT_GRABABLE_MASK;
	
	int rows = [self numberForA4:10 A5:11];
	
	// Add the dominoes.
	for(int i=0; i<rows; i++){
		for(int j=0; j<(rows - i); j++){
			cpVect offset = cpv((j - (rows - 1 - i)*0.5f)*1.5f*HEIGHT, (i + 0.5f)*(HEIGHT + 2*WIDTH) - WIDTH - 240);
			[self addDomino:offset flipped:FALSE];
			[self addDomino:cpvadd(offset, cpv(0, (HEIGHT + WIDTH)/2.0f)) flipped:TRUE];
			
			if(j == 0){
				[self addDomino:cpvadd(offset, cpv(0.5f*(WIDTH - HEIGHT), HEIGHT + WIDTH)) flipped:FALSE];
			}
			
			if(j != rows - i - 1){
				[self addDomino:cpvadd(offset, cpv(HEIGHT*0.75f, (HEIGHT + 3*WIDTH)/2.0f)) flipped:TRUE];
			} else {
				[self addDomino:cpvadd(offset, cpv(0.5f*(HEIGHT - WIDTH), HEIGHT + WIDTH)) flipped:FALSE];
			}
		}
	}
	
	{
		cpFloat radius = 10.0f;
		cpFloat mass = 5.0f;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
		body.pos = cpv(520, -180);
		body.vel = cpv(-400, 100);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
		shape.elasticity = 0.0f;
		shape.friction = 0.9f;
	}
}

-(NSTimeInterval)preferredTimeStep;
{
	return 1.0/120.0;
}

@end
