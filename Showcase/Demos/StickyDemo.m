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

#define STICK_SENSOR_THICKNESS 3.0f

-(void)setup
{
	self.space.gravity = cpv(0, -1000);
	
	id stickyType = @"sticky";
	
	[self addBounds:self.demoBounds collisionType:stickyType];
	
	for(int i=0; i<5; i++){
		for(int j=0; j<5; j++){
			cpFloat radius = 30.0f;
			ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:1.0 andMoment:cpMomentForCircle(1.0, 0.0, radius, cpvzero)]];
			body.pos = cpv((i-2)*2.0*radius, (j-2)*2.0*radius);
			
			ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
			shape.friction = 0.9;
			
			ChipmunkShape *sensor = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius + STICK_SENSOR_THICKNESS offset:cpvzero]];
			sensor.sensor = TRUE;
			sensor.collisionType = stickyType;
		}
	}
	
	[self.space addCollisionHandler:self typeA:stickyType typeB:stickyType
		begin:nil
		preSolve:@selector(stickyPreSolve:space:)
		postSolve:nil
		separate:@selector(stickySeparate:space:)
	];
}

static void
boundSeg(ChipmunkSpace *space, cpVect a, cpVect b, cpCollisionType stickyType)
{
	ChipmunkStaticSegmentShape *bound = [space add:[ChipmunkStaticSegmentShape segmentWithBody:space.staticBody from:a to:b radius:0.0]];
	bound.friction = 1.0;
	
	ChipmunkStaticSegmentShape *sticky = [space add:[ChipmunkStaticSegmentShape segmentWithBody:space.staticBody from:a to:b radius:STICK_SENSOR_THICKNESS]];
	sticky.collisionType = stickyType;
	sticky.sensor = TRUE;
}

- (void)addBounds:(CGRect)bounds collisionType:(id)stickyType
{
	cpFloat l = bounds.origin.x;
	cpFloat r = bounds.origin.x + bounds.size.width;
	cpFloat b = bounds.origin.y;
	cpFloat t = bounds.origin.y + bounds.size.height;
	
	ChipmunkSpace *space = self.space;
	boundSeg(space, cpv(l,b), cpv(l,t), stickyType);
	boundSeg(space, cpv(l,t), cpv(r,t), stickyType);
	boundSeg(space, cpv(r,t), cpv(r,b), stickyType);
	boundSeg(space, cpv(r,b), cpv(l,b), stickyType);
}


-(bool)stickyPreSolve:(cpArbiter *)arb space:(ChipmunkSpace *)space
{
	// All the sticky surfaces are covered by sensor shapes.
	// The sensor shapes give everything a little thicknes 
	
	// If sensor pairs don't already
	if(!cpArbiterGetUserData(arb) && cpArbiterGetDepth(arb, 0) <= -2.0f*STICK_SENSOR_THICKNESS){
		CHIPMUNK_ARBITER_GET_BODIES(arb, body_a, body_b);
		cpVect point = cpArbiterGetPoint(arb, 0);
		
		// Create a joint at the contact point to hold the body in place.
		ChipmunkConstraint *joint = [ChipmunkPivotJoint pivotJointWithBodyA:body_a bodyB:body_b pivot:point];
		
		// Give it a finite force for the stickyness.
		joint.maxForce = 1e4;
		
		// Schedule a post-step() callback to add the joint.
		[space smartAdd:joint];
		
		// Store the joint on the arbiter so we can remove it later.
		// This is an __unsafe_unretained pointer.
		cpArbiterSetUserData(arb, joint);
	}
	
	return cpTrue;
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
