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

@interface PlanetDemo : ShowcaseDemo @end
@implementation PlanetDemo {
	ChipmunkBody *_planetBody;
}

-(NSString *)name
{
	return @"Planet";
}

static const cpFloat gravityStrength = 5.0e6f;

static void
PlanetGravityVelocityFunc(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt)
{
	// Gravitational acceleration is proportional to the inverse square of
	// distance, and directed toward the origin. The central planet is assumed
	// to be massive enough that it affects the satellites but not vice versa.
	cpVect pos = cpBodyGetPos(body);
	cpFloat sqdist = cpvlengthsq(pos);
	cpVect g = cpvmult(pos, -gravityStrength/(sqdist*cpfsqrt(sqdist)));
	
	cpBodyUpdateVelocity(body, g, damping, dt);
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

-(void)addBox
{
	const cpFloat size = 15.0f;
	const cpFloat mass = 1.0f;
	
	cpVect pos = rand_pos();
	
	ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, size, size)]];
	body.body->velocity_func = PlanetGravityVelocityFunc;
	body.pos = pos;
	
	// Set the box's velocity to put it into a circular orbit from its
	// starting position.
	cpFloat r = cpvlength(pos);
	cpFloat v = 0.99*cpfsqrt(gravityStrength/r)/r;
	body.vel = cpvmult(cpvperp(pos), v);
	
	// Set the box's angular velocity to match its orbital period and
	// align its initial angle with its position.
	body.angVel = v;
	body.angle = cpfatan2(pos.y, pos.x);
	
	ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:size height:size]];
	shape.elasticity = 0.0f;
	shape.friction = 0.7f;
}

-(void)setup
{
	_planetBody = [self.space add:[ChipmunkBody bodyWithMass:INFINITY andMoment:INFINITY]];
	_planetBody.angVel = -4.0f;
	
	NSUInteger count = [self numberForA4:250 A5:400];
	for(int i=0; i < count; i++) [self addBox];
	
	ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:_planetBody radius:70.0f offset:cpvzero]];
	shape.elasticity = 1.0f;
	shape.friction = 1.0f;
	shape.layers = NOT_GRABABLE_MASK;
}

@end
