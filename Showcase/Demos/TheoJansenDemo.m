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

@interface TheoJansenDemo : ShowcaseDemo @end
@implementation TheoJansenDemo

-(NSString *)name
{
	return @"Theo Jansen Machine";
}

#define SEG_RADIUS 3.0f
static NSString *GROUP = @"group";

//static void
//make_leg(cpFloat side, cpFloat offset, cpBody *chassis, cpBody *crank, cpVect anchor)
-(void)makeLeg:(cpFloat)side offset:(cpFloat)offset chassis:(ChipmunkBody *)chassis crank:(ChipmunkBody *)crank anchor:(cpVect)anchor
{
	cpFloat leg_mass = 1.0f;
	cpVect a, b;
	ChipmunkShape *shape;
	
	a = cpvzero, b = cpv(0.0f, side);
	ChipmunkBody *upper_leg = [self.space add:[ChipmunkBody bodyWithMass:leg_mass andMoment:cpMomentForSegment(leg_mass, a, b, 0.0)]];
	upper_leg.position = cpv(offset, 0.0);
	
	shape = [self.space add:[ChipmunkSegmentShape segmentWithBody:upper_leg from:a to:b radius:SEG_RADIUS]];
	shape.filter = CP_SHAPE_FILTER_NONE;
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:chassis bodyB:upper_leg anchorA:cpv(offset, 0) anchorB:cpvzero]];
	
	a = cpvzero, b = cpv(0.0f, -1.0f*side);
	ChipmunkBody *lower_leg = [self.space add:[ChipmunkBody bodyWithMass:leg_mass andMoment:cpMomentForSegment(leg_mass, a, b, 0.0)]];
	lower_leg.position = cpv(offset, -side);
	
	shape = [self.space add:[ChipmunkSegmentShape segmentWithBody:lower_leg from:a to:b radius:SEG_RADIUS]];
	shape.filter = cpShapeFilterNew(GROUP, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	shape = [self.space add:[ChipmunkCircleShape circleWithBody:lower_leg radius:SEG_RADIUS*2.0f offset:b]];
	shape.filter = cpShapeFilterNew(GROUP, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	shape.elasticity = 0.0;
	shape.friction = 1.0;
	
	[self.space add:[ChipmunkPinJoint pinJointWithBodyA:chassis bodyB:lower_leg anchorA:cpv(offset, 0.0f) anchorB:cpvzero]];
	[self.space add:[ChipmunkGearJoint gearJointWithBodyA:upper_leg bodyB:lower_leg phase:0.0f ratio:1.0f]];
	
	cpFloat diag = cpfsqrt(side*side + offset*offset);
	
	ChipmunkPinJoint *pin1 = [self.space add:[ChipmunkPinJoint pinJointWithBodyA:crank bodyB:upper_leg anchorA:anchor anchorB:cpv(0.0f, side)]];
	pin1.dist = diag;
	
	ChipmunkPinJoint *pin2 = [self.space add:[ChipmunkPinJoint pinJointWithBodyA:crank bodyB:lower_leg anchorA:anchor anchorB:cpvzero]];
	pin2.dist = diag;
}

-(void)setup
{
	self.space.iterations = 20;
	
	cpShapeFilter filter = cpShapeFilterNew(CP_NO_GROUP, NOT_GRABABLE_MASK, NOT_GRABABLE_MASK);
	[self.space addBounds:self.demoBounds thickness:10.0 elasticity:1.0 friction:1.0 filter:filter collisionType:nil];
	
	cpFloat offset = 30.0f;
	ChipmunkShape *shape;

	// make chassis
	cpFloat chassis_mass = 2.0f;
	cpVect a = cpv(-offset, 0.0f);
	cpVect b = cpv(offset, 0.0f);
	ChipmunkBody *chassis = [self.space add:[ChipmunkBody bodyWithMass:chassis_mass andMoment:cpMomentForSegment(chassis_mass, a, b, 0.0)]];
	
	shape = [self.space add:[ChipmunkSegmentShape segmentWithBody:chassis from:a to:b radius:SEG_RADIUS]];
	shape.filter = cpShapeFilterNew(GROUP, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	// make crank
	cpFloat crank_mass = 1.0f;
	cpFloat crank_radius = 13.0f;
	ChipmunkBody *crank = [self.space add:[ChipmunkBody bodyWithMass:crank_mass andMoment:cpMomentForCircle(crank_mass, crank_radius, 0.0f, cpvzero)]];
	
	shape = [self.space add:[ChipmunkCircleShape circleWithBody:crank radius:crank_radius offset:cpvzero]];
	shape.filter = cpShapeFilterNew(GROUP, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:chassis bodyB:crank anchorA:cpvzero anchorB:cpvzero]];
	
	cpFloat side = 30.0f;
	
	int num_legs = 2;
	for(int i=0; i < num_legs; i++){
		[self makeLeg:side offset: offset chassis:chassis crank:crank anchor:cpvmult(cpvforangle((cpFloat)(2*i+0)/(cpFloat)num_legs*M_PI), crank_radius)];
		[self makeLeg:side offset:-offset chassis:chassis crank:crank anchor:cpvmult(cpvforangle((cpFloat)(2*i+1)/(cpFloat)num_legs*M_PI), crank_radius)];
	}
}

-(void)tick:(cpFloat)dt;
{
	self.space.gravity = cpvmult([Accelerometer getAcceleration], 500.0);
	[super tick:dt];
}

@end
