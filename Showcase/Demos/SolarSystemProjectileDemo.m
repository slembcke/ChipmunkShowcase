/* Copyright (c) 2012 Scott Lembcke and Howling Moon Software
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "ShowcaseDemo.h"
#import "ChipmunkHastySpace.h"


@interface PlanetoidBody : ChipmunkBody

@property(nonatomic, assign) cpFloat gravity;

@end


// In order to provide the planetary gravity, I'm going to make a ChipmunkSpace subclass to
// track the planetoids (things big enough to have gravity). Then the satellites can ask the
// space what gravity for them should be.

// If you are going to override ChipmunkSpace, you should override ChipmunkHastySpace instead.
// It's the ARM/multicore accelerated version of ChipmunkSpace provided by ChipmunkPro.
@interface SolarSystemProjectileSpace : ChipmunkHastySpace

@property(nonatomic, readonly) NSMutableArray *planetoids;

@end


@implementation SolarSystemProjectileSpace {
@protected
	NSMutableArray *_planetoids;
}

@synthesize planetoids = _planetoids;

-(id)init
{
	if((self = [super init])){
		_planetoids = [[NSMutableArray alloc] init];
	}
	
	return self;
}

-(cpVect)gravityAt:(cpVect)pos
{
	cpVect g = cpvzero;
	
	// Loop over all the planetoids and add their gravities together.
	for(PlanetoidBody *planetoid in _planetoids){
		cpVect delta = cpvsub(pos, planetoid.pos);
		cpFloat sqdist = cpvlengthsq(delta);
		g = cpvadd(g, cpvmult(delta, -planetoid.gravity/(sqdist*cpfsqrt(sqdist))));
	}
	
	return g;
}


@end


@implementation PlanetoidBody {
@public
	cpFloat _gravity;
}

@synthesize gravity = _gravity;

-(id)initWithGravity:(cpFloat)gravity;
{
	if((self = [super initWithMass:INFINITY andMoment:INFINITY])){
		_gravity = gravity;
	}
	
	return self;
}

-(void)addToSpace:(SolarSystemProjectileSpace *)space
{
	[super addToSpace:space];
	[space.planetoids addObject:self];
}

-(void)removeFromSpace:(SolarSystemProjectileSpace *)space
{
	[space.planetoids removeObject:self];
	[super removeFromSpace:space];
}

@end


// Make a custom body subclass with a custom velocity integration method.
@interface SatelliteBody : ChipmunkBody @end
@implementation SatelliteBody

-(void)updateVelocity:(cpFloat)dt gravity:(cpVect)gravity damping:(cpFloat)damping
{
	// The ChipmunkSpace object reference is stored in the user data pointer of the space.
	// Use that to recalculate the fancy multi-planet gravity for us.
	SolarSystemProjectileSpace *space = (SolarSystemProjectileSpace *)self.space;
	[super updateVelocity:dt gravity:[space gravityAt:self.pos] damping:damping];
}

@end


// Now actually implement the demo. \o/
@interface SolarSystemProjectileDemo : ShowcaseDemo @end
@implementation SolarSystemProjectileDemo {
	ChipmunkBody *_planetBody;
	ChipmunkBody *_moonBody;
}

-(NSString *)name
{
	return @"Solar System Projectiles";
}

-(Class)spaceClass
{
	return [SolarSystemProjectileSpace class];
}

static cpVect
rand_pos()
{
	cpVect v;
	do {
		v = cpvmult(frand_unit_circle(), 500);
	} while(cpvlength(v) < 100.0f);
	
	return v;
}

-(void)addBall:(cpVect)direction at:(cpVect)point
{
	const cpFloat radius = 5.0f;
	const cpFloat mass = 1.0f;
	
	ChipmunkBody *body = [self.space add:[SatelliteBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
	body.pos = point;
    body.vel = cpvmult(direction, 150);
	
	ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
	shape.elasticity = 0.0f;
	shape.friction = 0.7f;
}

static const cpFloat MoonOrbitDist = 240.0;

-(void)setup
{
    cpFloat gravity = 2e6;
	{
		ChipmunkBody *body = [self.space add:[[PlanetoidBody alloc] initWithGravity:gravity]];
        body.pos = cpv(0, 0);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:30.0f offset:cpvzero]];
		shape.elasticity = 1.0f;
		shape.friction = 1.0f;
		shape.layers = NOT_GRABABLE_MASK;
	}
    
	{
		ChipmunkBody *body = [self.space add:[[PlanetoidBody alloc] initWithGravity:gravity]];
        body.pos = cpv(200, 0);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:30.0f offset:cpvzero]];
		shape.elasticity = 1.0f;
		shape.friction = 1.0f;
		shape.layers = NOT_GRABABLE_MASK;
	}
    
	{
		ChipmunkBody *body = [self.space add:[[PlanetoidBody alloc] initWithGravity:gravity]];
        body.pos = cpv(100, -200);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:30.0f offset:cpvzero]];
		shape.elasticity = 1.0f;
		shape.friction = 1.0f;
		shape.layers = NOT_GRABABLE_MASK;
	}
    
	{
		ChipmunkBody *body = [self.space add:[[PlanetoidBody alloc] initWithGravity:gravity]];
        body.pos = cpv(250, 200);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:30.0f offset:cpvzero]];
		shape.elasticity = 1.0f;
		shape.friction = 1.0f;
		shape.layers = NOT_GRABABLE_MASK;
	}
    
	{
		ChipmunkBody *body = [self.space add:[[PlanetoidBody alloc] initWithGravity:gravity]];
        body.pos = cpv(-120, 150);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:30.0f offset:cpvzero]];
		shape.elasticity = 1.0f;
		shape.friction = 1.0f;
		shape.layers = NOT_GRABABLE_MASK;
	}
    
	{
		ChipmunkBody *body = [self.space add:[[PlanetoidBody alloc] initWithGravity:gravity]];
        body.pos = cpv(-180, -190);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:30.0f offset:cpvzero]];
		shape.elasticity = 1.0f;
		shape.friction = 1.0f;
		shape.layers = NOT_GRABABLE_MASK;
	}
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
    for(UITouch *touch in touches){
        cpVect origin = cpv(-320, 0);
        cpVect point = [self convertTouch:touch];
        cpVect direction = cpvnormalize(cpvsub(point, origin));
        
        [self addBall:direction at:origin];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {}

@end
