#define CP_ALLOW_PRIVATE_ACCESS

#import "ShowcaseDemo.h"
#import "ChipmunkHastySpace.h"

@interface LogoSmashDemo : ShowcaseDemo @end
@implementation LogoSmashDemo

-(NSString *)name
{
	return @"Logo Smash";
}

-(BOOL)showName
{
	return FALSE;
}

static const int image_width = 96;
static const int image_height = 18;
static const int image_row_length = 12;

static const unsigned char image_bitmap[] = {
	0,0,0,0,0,0,0,0,0,0,0,96,124,-16,0,0,0,0,0,0,0,0,0,-32,-13,-8,0,0,0,0,0,
	0,0,0,1,-32,-25,-8,0,0,0,0,0,0,0,0,25,-32,-20,-8,0,0,0,0,0,0,0,0,57,-16,
	-52,-8,0,0,0,0,0,0,0,0,125,-16,-36,0,0,0,0,0,0,0,0,0,-3,-16,-36,1,-25,-67,
	-1,63,31,-68,-9,-113,-1,-16,-100,1,-25,-67,-1,-65,31,-68,-9,-49,127,-8,-68,
	1,-25,-67,-25,-65,-65,-68,-9,-49,127,-4,-68,1,-25,-67,-25,-65,-65,-68,-9,
	-17,63,-2,-68,1,-1,-67,-25,-65,-1,-68,-9,-1,63,127,-68,-7,-1,-67,-25,-65,
	-1,-68,-9,-1,63,63,-68,-7,-25,-67,-1,-67,-9,-68,-9,-1,31,-98,-68,-7,-25,-67,
	-1,61,-9,-68,-9,-65,31,-116,-65,-7,-25,-67,-32,61,-9,-68,-9,-97,15,-64,-65,
	-7,-25,-67,-32,60,-25,-65,-9,-97,15,-64,95,-15,-25,-67,-32,60,-25,-97,-25,-113,7,0
};

static inline int
get_pixel(int x, int y)
{
	return (image_bitmap[(x>>3) + y*image_row_length]>>(~x&0x7)) & 1;
}

-(void)addBall:(cpVect)pos
{
	ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:1.0 andMoment:INFINITY]];
	body.pos = pos;
	
	ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:1.9 offset:cpvzero]];
	shape.elasticity = 0.0;
	shape.friction = 0.0;
}

-(void)setup
{
	self.space = [[ChipmunkHastySpace alloc] init];
	self.space.iterations = 1;
	
	cpSpaceUseSpatialHash(self.space.space, 4.0, 10000);
	
	for(int y=0; y<image_height; y++){
		for(int x=0; x<image_width; x++){
			if(!get_pixel(x, y)) continue;
			
			[self addBall:cpv(4*(x - image_width/2 + 0.05*frand()), 4*(image_height/2 - y + 0.05*frand()))];
		}
	}
	
	ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:INFINITY andMoment:INFINITY]];
	body.pos = cpv(-1000, -10);
	body.vel = cpv(400, 0);
	
	ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:8.0 offset:cpvzero]];
	shape.elasticity = 0.0;
	shape.friction = 0.0;
	shape.layers = NOT_GRABABLE_MASK;
}

-(void)prepareStaticRenderer:(PolyRenderer *)renderer {}


struct RenderContext {
	__unsafe_unretained PolyRenderer *renderer;
	NSTimeInterval accumulator;	
};

static void
RenderDot(cpBody *body, struct RenderContext *context)
{
	cpVect pos = cpvadd(body->p, cpvmult(body->v, context->accumulator));
	[context->renderer drawDot:pos radius:4.0 color:SHAPE_OUTLINE_COLOR];
}

-(void)render:(PolyRenderer *)renderer showContacts:(BOOL)showContacts;
{
	cpSpaceEachBody(self.space.space, (cpSpaceBodyIteratorFunc)RenderDot, &(struct RenderContext){renderer, self.accumulator});
	
	if(showContacts){
		// This is using the private API to efficiently render the collision points.
		// Don't do this in a real game!
		cpArray *arbiters = self.space.space->arbiters;
		for(int i=0; i<arbiters->num; i++){
			cpArbiter *arb = (cpArbiter*)arbiters->arr[i];
			
			for(int i=0; i<arb->numContacts; i++){
				[renderer drawDot:arb->contacts[i].p radius:2.0 color:CONTACT_COLOR];
			}
		}
	}
}


@end
