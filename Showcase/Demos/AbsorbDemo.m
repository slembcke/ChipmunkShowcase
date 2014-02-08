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

// You need to import this if you want to modify shapes.
// It's an "unsafe" API (read the comments) so it doesn't contain an Obj-C wrapper.
#import "chipmunk_unsafe.h"

@interface AbsorbDemo : ShowcaseDemo @end
@implementation AbsorbDemo

-(NSString *)name
{
	return @"Absorb";
}

#define DENSITY (1.0e-2)

NSString *COLLISION_ID = @"COLLISION_ID";

-(bool)preSolve:(cpArbiter *)arbiter space:(ChipmunkSpace*)space
{
	// Get the two colliding shapes
	CHIPMUNK_ARBITER_GET_SHAPES(arbiter, ball1, ball2);
	ChipmunkCircleShape *bigger = (id)ball1;
	ChipmunkCircleShape *smaller = (id)ball2;
	
	if(smaller.radius > bigger.radius){
		ChipmunkCircleShape *tmp = bigger;
		bigger = smaller;
		smaller = tmp;
	}
	
	cpFloat r1 = bigger.radius;
	cpFloat r2 = smaller.radius;
	cpFloat area = r1*r1 + r2*r2;
	cpFloat dist = cpfmax(cpvdist(bigger.body.position, smaller.body.position), cpfsqrt(area));
	
	cpFloat r1_new = (2.0*dist + cpfsqrt(8.0*area - 4.0*dist*dist))/4.0;
	
	// First update the velocity by gaining the absorbed momentum.
	cpFloat old_mass = bigger.body.mass;
	cpFloat new_mass = r1_new*r1_new*DENSITY;
	cpFloat gained_mass = new_mass - old_mass;
	bigger.body.velocity = cpvmult(cpvadd(cpvmult(bigger.body.velocity, old_mass), cpvmult(smaller.body.velocity, gained_mass)), 1.0/new_mass);
	
	bigger.body.mass = new_mass;
	cpCircleShapeSetRadius(bigger.shape, r1_new);
		
	cpFloat r2_new = dist - r1_new;
	if(r2_new > 0.0){
		smaller.body.mass = r2_new*r2_new*DENSITY;
		cpCircleShapeSetRadius(smaller.shape, r2_new);
	} else {
		// If smart remove is called from within a callback
		// it will schedule a post-step callback to perform the removal automatically.
		// NICE!
		[space smartRemove:smaller];
		[space smartRemove:smaller.body];
	}
	
	return FALSE;
}


-(void)setup
{
	cpBB bounds = self.demoBounds;
	cpShapeFilter filter = cpShapeFilterNew(CP_NO_GROUP, NOT_GRABABLE_MASK, NOT_GRABABLE_MASK);
	[self.space addBounds:bounds thickness:10.0 elasticity:1.0 friction:1.0 filter:filter collisionType:nil];
	
	for(int i=0; i<5000; i++){
		cpFloat radius = cpflerp(5.0, 20.0, frand());
		cpFloat mass = DENSITY*radius*radius;
		
		ChipmunkBody *body = [ChipmunkBody bodyWithMass:mass andMoment:INFINITY];
		body.position = cpv(cpflerp(bounds.l, bounds.r, frand()), cpflerp(bounds.b, bounds.t, frand()));
//		body.position = cpv(frand()*(bounds.size.width - 2.0*radius) + bounds.origin.x, frand()*(bounds.size.height - 2.0*radius) + bounds.origin.y);
		body.velocity = cpvmult(frand_unit_circle(), 2.0);
		
		ChipmunkShape *shape = [ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero];
		shape.elasticity = 1.0;
		shape.friction = 0.0;
		shape.collisionType = COLLISION_ID;
		
		if(![self.space shapeTest:shape]){
			[self.space add:body];
			[self.space add:shape];
		}
	}
	
	[self.space addCollisionHandler:self typeA:COLLISION_ID typeB:COLLISION_ID begin:nil preSolve:@selector(preSolve:space:) postSolve:nil separate:nil];
}

-(void)render:(PolyRenderer *)renderer showContacts:(BOOL)showContacts;
{
	Class circle_class = [ChipmunkCircleShape class];
	
	for(ChipmunkShape *shape in self.space.shapes){
		if([shape isKindOfClass:circle_class]){
			ChipmunkCircleShape *circle = (id)shape;
			[renderer drawDot:circle.body.position radius:circle.radius color:circle.color];
		}
	}
}

@end
