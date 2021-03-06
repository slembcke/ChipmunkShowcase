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

@interface BreakableSlideJoint : ChipmunkSlideJoint
@end

@implementation BreakableSlideJoint

-(void)postSolve:(ChipmunkSpace *)space
{
	cpFloat dt = space.currentTimeStep;
	
	// Convert the impulse to a force by dividing it by the timestep.
	cpFloat force = self.impulse/dt;
	cpFloat maxForce = self.maxForce;

	// If the force is almost as big as the joint's max force, break it.
	if(force > 0.9*maxForce){
		[space smartRemove:self];
	}
}

@end


@interface BreakableChainsDemo : ShowcaseDemo @end
@implementation BreakableChainsDemo

-(NSString *)name
{
	return @"Breakable Chains";
}

#define CHAIN_COUNT 8
#define LINK_COUNT 10

-(void)setup
{
	self.space.iterations = 30;
	
	cpShapeFilter filter = cpShapeFilterNew(CP_NO_GROUP, NOT_GRABABLE_MASK, NOT_GRABABLE_MASK);
	[self.space addBounds:self.demoBounds thickness:10.0 elasticity:1.0 friction:1.0 filter:filter collisionType:nil];
	
	cpFloat mass = 1;
	cpFloat width = 20;
	cpFloat height = 30;
	
	cpFloat spacing = width*0.3;
	
	// Add lots of boxes.
	for(int i=0; i < CHAIN_COUNT; i++){
		ChipmunkBody *prev = nil;
		
		for(int j=0; j < LINK_COUNT; j++){
			cpVect pos = cpv(40*(i - (CHAIN_COUNT - 1)/2.0), 240 - (j + 0.5)*height - (j + 1)*spacing);
			
			ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, width, height)]];
			body.position = pos;
			
			ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:width height:height radius:0.0]];
			shape.friction = 0.8f;
			
			ChipmunkConstraint *constraint = nil;
			if(prev == nil){
				constraint = [self.space add:[BreakableSlideJoint slideJointWithBodyA:body bodyB:self.space.staticBody anchorA:cpv(0, height/2) anchorB:cpv(pos.x, 240) min:0.0 max:spacing]];
			} else {
				constraint = [self.space add:[BreakableSlideJoint slideJointWithBodyA:body bodyB:prev anchorA:cpv(0, height/2) anchorB:cpv(0, -height/2) min:0.0 max:spacing]];
			}
			
			constraint.maxForce = 8.0e4;
			
			prev = body;
		}
	}
	
	{
		cpFloat radius = 15.0f;
		cpFloat mass = 10.0;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
		body.position = cpv(0, -240 + radius + 5);
		body.velocity = cpv(0, 300);

		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
		shape.elasticity = 0.0f;
		shape.friction = 0.9f;
	}
}

-(NSTimeInterval)preferredTimeStep;
{
	return 1.0/120.0;
}

-(void)tick:(cpFloat)dt;
{
	self.space.gravity = cpvmult([Accelerometer getAcceleration], 100.0);
	[super tick:dt];
}

@end
