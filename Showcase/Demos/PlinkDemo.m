#import "ShowcaseDemo.h"

@interface PlinkDemo : ShowcaseDemo @end
@implementation PlinkDemo {
	NSUInteger _count;
}

-(NSString *)name
{
	return @"Plink";
}

-(void)setup
{
	self.space.iterations = 5;
	
	// Vertexes for a triangle shape.
	cpVect verts[] = {
		cpv(-15,-15),
		cpv(  0, 10),
		cpv( 15,-15),
	};

	// Create the static triangles.
	for(int j=0; j<6; j++){
		int columns = (j%2 == 0 ? 9 : 8);
		for(int i=0; i<columns; i++){
			cpFloat stagger = (j%2)*40;
			cpVect offset = cpv(i*80 - 320 + stagger, j*70 - 240);
			ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape polyWithBody:self.staticBody count:3 verts:verts offset:offset]];
			shape.elasticity = 1.0; shape.friction = 1.0;
			shape.layers = NOT_GRABABLE_MASK;
		}
	}
	
	_count = [self numberForA4:300 A5:600];
}

-(void)tick:(cpFloat)dt;
{
//	_space.gravity = cpvmult([Accelerometer getAcceleration], 100);
	self.space.gravity = cpv(0.0, -100);
	
	NSArray *bodies = self.space.bodies;
	if([bodies count] < _count){
		cpFloat size = 7.0;
		
		cpVect pentagon[5];
		for(int i=0; i<5; i++){
			cpFloat angle = -2*M_PI*i/5.0;
			pentagon[i] = cpv(size*cos(angle), size*sin(angle));
		}
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:1.0 andMoment:cpMomentForPoly(1.0, 5, pentagon, cpvzero)]];
		cpFloat x = rand()/(cpFloat)RAND_MAX*640 - 320;
		cpFloat y = rand()/(cpFloat)RAND_MAX*300 + 350;
		body.pos = cpv(x, y);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape polyWithBody:body count:5 verts:pentagon offset:cpvzero]];
		shape.elasticity = 0.0; shape.friction = 0.4;
	}
	
	for(ChipmunkBody *body in bodies){
		cpVect pos = body.pos;
		if(pos.y < -260 || fabsf(pos.x) > 400){
			body.pos = cpv(((cpFloat)rand()/(cpFloat)RAND_MAX)*640.0 - 320.0, 260);
		}
	}
	
	[super tick:dt];
}

@end
