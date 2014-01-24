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

@interface GrabberDemo : ShowcaseDemo @end
@implementation GrabberDemo

-(NSString *)name
{
	return @"Grabber";
}

// Wasn't sure how big to make it at first.
#define SCALE 100.0
#define THICKNESS 10.0

NSString *SCISSOR_GROUP = @"SCISSOR_GROUP";

-(ChipmunkBody *)addScissorAt:(cpVect)pos angle:(cpFloat)angle
{
	cpFloat mass = 2.0;
	cpFloat moment = cpMomentForBox(mass, 2.0*SCALE + THICKNESS, THICKNESS);
	ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:moment]];
	body.position = pos;
	body.angle = angle;
	
	ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:2.0*SCALE + THICKNESS height:THICKNESS radius:0.0]];
	shape.friction = 1.0;
	shape.filter = cpShapeFilterNew(SCISSOR_GROUP, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	return body;
}

-(void)addGripperToBody:(ChipmunkBody *)body withBB:(cpBB)bb
{
	ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body bb:bb radius:0.0]];
	shape.friction = 1.0;
}

-(void)setup
{
	self.space.gravity = cpv(0, -600);
	self.space.damping = 0.4;
	self.space.iterations = 20;
	
	cpShapeFilter filter = cpShapeFilterNew(CP_NO_GROUP, NOT_GRABABLE_MASK, NOT_GRABABLE_MASK);
	[self.space addBounds:self.demoBounds thickness:10.0 elasticity:1.0 friction:1.0 filter:filter collisionType:nil];
	
	ChipmunkBody *scissor1 = [self addScissorAt:cpvzero angle:0.0];
	ChipmunkBody *scissor2 = [self addScissorAt:cpvzero angle:M_PI_2];
	ChipmunkBody *scissor3 = [self addScissorAt:cpv(SCALE, SCALE) angle:0.0];
	ChipmunkBody *scissor4 = [self addScissorAt:cpv(SCALE, SCALE) angle:M_PI_2];
	
	// Add handles
	cpFloat handleSize = 30.0;
	[self.space add:[ChipmunkCircleShape circleWithBody:scissor1 radius:handleSize offset:cpv(-SCALE, 0)]];
	[self.space add:[ChipmunkCircleShape circleWithBody:scissor2 radius:handleSize offset:cpv(-SCALE, 0)]];
	
	// Add grippers
	[self addGripperToBody:scissor3 withBB:cpBBNew(SCALE - THICKNESS/2.0,  THICKNESS/2.0, SCALE + THICKNESS/2.0,  SCALE/2.0)];
	[self addGripperToBody:scissor4 withBB:cpBBNew(SCALE - THICKNESS/2.0, -SCALE/2.0, SCALE + THICKNESS/2.0, -THICKNESS/2.0)];
	
	[self.space add:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:scissor1 bodyB:scissor2 min:M_PI/2.0 max:0.8*M_PI]];
	[self.space add:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:scissor3 bodyB:scissor4 min:M_PI/2.0 max:0.8*M_PI]];
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:scissor1 bodyB:scissor2 pivot:scissor1.position]];
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:scissor3 bodyB:scissor4 pivot:scissor3.position]];
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:scissor1 bodyB:scissor4 pivot:cpv(SCALE, 0)]];
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:scissor2 bodyB:scissor3 pivot:cpv(0, SCALE)]];
	
	{
		cpFloat size = SCALE - THICKNESS;
		cpFloat mass = 4.0f;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, size, size)]];
		body.position = cpv(-200, 0);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:size height:size radius:0.0]];
		shape.elasticity = 0.0f;
		shape.friction = 0.9f;
	}
}

-(NSTimeInterval)preferredTimeStep
{
	return 1.0/120.0;
}

-(void)tick:(cpFloat)dt
{
	self.space.gravity = cpvmult([Accelerometer getAcceleration], 600);
	[super tick:dt];
}

@end
