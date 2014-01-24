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

@interface StickyDemo : ShowcaseDemo @end
@implementation StickyDemo

-(NSString *)name
{
	return @"Sticky";
}

-(NSTimeInterval)preferredTimeStep
{
	return 1.0/120.0;
}

-(void)setup
{
	self.space.gravity = cpv(0, -1000);
	
	id stickyType = @"sticky";
	
	[self.space addBounds:self.demoBounds thickness:10.0 elasticity:0.0 friction:1.0 filter:CP_SHAPE_FILTER_ALL collisionType:stickyType];
	
	for(int i=0; i<10; i++){
		for(int j=0; j<10; j++){
			cpFloat radius = 15.0f;
			cpFloat mass = 0.25;
			
			ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
			body.position = cpv((i-5)*2.0*radius, (j-5)*2.0*radius);
			
			ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
			shape.friction = 0.9;
			shape.collisionType = stickyType;
		}
	}
	
	[self.space addCollisionHandler:self typeA:stickyType typeB:stickyType
		begin:nil
		preSolve:@selector(stickyPreSolve:space:)
		postSolve:nil
		separate:@selector(stickySeparate:space:)
	];
}

-(bool)stickyPreSolve:(cpArbiter *)arb space:(ChipmunkSpace *)space
{
	// We want to fudge the collisions a bit to allow shapes to overlap more.
	// This simulates their squishy sticky surface, and more importantly
	// keeps them from separating and destroying the joint.
	
	const cpFloat skin_thickness = 5.0;
	
	// Track the deepest collision point and use that to determine if a rigid collision should occur.
	cpFloat deepest = INFINITY;
	
	// Grab the contact set and iterate over them.
	cpContactPointSet contacts = cpArbiterGetContactPointSet(arb);
	for(int i=0; i<contacts.count; i++){
		// Sink the contact points into the surface of each shape.
		contacts.points[i].pointA = cpvsub(contacts.points[i].pointA, cpvmult(contacts.normal, skin_thickness));
		contacts.points[i].pointB = cpvadd(contacts.points[i].pointB, cpvmult(contacts.normal, skin_thickness));
		deepest = cpfmin(deepest, contacts.points[i].distance);// + 2.0f*STICK_SENSOR_THICKNESS);
	}
	
	// Set the new contact point data.
	cpArbiterSetContactPointSet(arb, &contacts);
	
	// If the shapes are overlapping enough, then create a
	// joint that sticks them together at the first contact point.
	if(!cpArbiterGetUserData(arb) && deepest <= 0.0f){
		CHIPMUNK_ARBITER_GET_BODIES(arb, bodyA, bodyB);
		cpVect anchorA = [bodyA worldToLocal:contacts.points[0].pointA];
		cpVect anchorB = [bodyB worldToLocal:contacts.points[0].pointB];
		
		// Create a joint at the contact point to hold the body in place.
		ChipmunkConstraint *joint = [ChipmunkPivotJoint pivotJointWithBodyA:bodyA bodyB:bodyB anchorA:anchorA anchorB:anchorB];
		
		// Give it a finite force for the stickyness.
		joint.maxForce = 6e3;
		
		// Schedule a post-step() callback to add the joint.
		[space smartAdd:joint];
		
		// Store the joint on the arbiter so we can remove it later.
		// This is an __unsafe_unretained pointer.
		cpArbiterSetUserData(arb, joint);
	}
	
	// Position correction and velocity are handled separately so changing
	// the overlap distance alone won't prevent the collision from occuring.
	// Explicitly the collision for this frame if the shapes don't overlap using the new distance.
	return (deepest <= -skin_thickness);
}

-(void)stickySeparate:(cpArbiter *)arb space:(ChipmunkSpace *)space
{
	ChipmunkConstraint *joint = (ChipmunkConstraint *)cpArbiterGetUserData(arb);
	
	if(joint){
		// The joint won't be removed until the step is done.
		// Need to disable it so that it won't apply itself.
		// Setting the force to 0 will do just that
		joint.maxForce = 0.0f;
		
		// Perform the removal in a post-step() callback.
		[space smartRemove:joint];
		
		// NULL out the reference to the joint.
		// Not required, but it's a good practice.
		cpArbiterSetUserData(arb, nil);
	}
}

@end
