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

@interface SpringiesDemo : ShowcaseDemo @end
@implementation SpringiesDemo

-(NSString *)name
{
	return @"Springies";
}

-(NSTimeInterval)preferredTimeStep
{
	return 1.0/120.0;
}

-(void)tick:(cpFloat)dt
{
	self.space.gravity = cpvmult([Accelerometer getAcceleration], 3000);
	[super tick:dt];
}

- (ChipmunkBody *)addBar:(cpVect)a to:(cpVect)b group:(id)group
{
	cpVect center = cpvmult(cpvadd(a, b), 1.0f/2.0f);
	cpFloat length = cpvlength(cpvsub(b, a));
	cpFloat mass = length/160.0f;
	
	ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:mass*length*length/12.0]];
	body.position = center;
	
	ChipmunkShape *shape = [self.space add:[ChipmunkSegmentShape segmentWithBody:body from:cpvsub(a, center) to:cpvsub(b, center) radius:10.0]];
	shape.filter = cpShapeFilterNew(group, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	return body;
}

- (void)setup
{
	ChipmunkBody *staticBody = self.staticBody;
	
	NSArray *groups = @[@0, @1, @2, @3, @4];
	
	ChipmunkBody *body1  = [self addBar:cpv(-240,  160) to:cpv(-160,   80) group:groups[1]];
	ChipmunkBody *body2  = [self addBar:cpv(-160,   80) to:cpv( -80,  160) group:groups[1]];
	ChipmunkBody *body3  = [self addBar:cpv(   0,  160) to:cpv(  80,    0) group:groups[0]];
	ChipmunkBody *body4  = [self addBar:cpv( 160,  160) to:cpv( 240,  160) group:groups[0]];
	ChipmunkBody *body5  = [self addBar:cpv(-240,    0) to:cpv(-160,  -80) group:groups[2]];
	ChipmunkBody *body6  = [self addBar:cpv(-160,  -80) to:cpv( -80,    0) group:groups[2]];
	ChipmunkBody *body7  = [self addBar:cpv( -80,    0) to:cpv(   0,    0) group:groups[2]];
	ChipmunkBody *body8  = [self addBar:cpv(   0,  -80) to:cpv(  80,  -80) group:groups[0]];
	ChipmunkBody *body9  = [self addBar:cpv( 240,   80) to:cpv( 160,    0) group:groups[3]];
	ChipmunkBody *body10 = [self addBar:cpv( 160,    0) to:cpv( 240,  -80) group:groups[3]];
	ChipmunkBody *body11 = [self addBar:cpv(-240,  -80) to:cpv(-160, -160) group:groups[4]];
	ChipmunkBody *body12 = [self addBar:cpv(-160, -160) to:cpv( -80, -160) group:groups[4]];
	ChipmunkBody *body13 = [self addBar:cpv(   0, -160) to:cpv(  80, -160) group:groups[0]];
	ChipmunkBody *body14 = [self addBar:cpv( 160, -160) to:cpv( 240, -160) group:groups[0]];
	
	ChipmunkSpace *space = self.space;
	
	[space add:[ChipmunkPivotJoint pivotJointWithBodyA: body1 bodyB: body2 anchorA:cpv( 40,-40) anchorB:cpv(-40,-40)]];
	[space add:[ChipmunkPivotJoint pivotJointWithBodyA: body5 bodyB: body6 anchorA:cpv( 40,-40) anchorB:cpv(-40,-40)]];
	[space add:[ChipmunkPivotJoint pivotJointWithBodyA: body6 bodyB: body7 anchorA:cpv( 40, 40) anchorB:cpv(-40,  0)]];
	[space add:[ChipmunkPivotJoint pivotJointWithBodyA: body9 bodyB:body10 anchorA:cpv(-40,-40) anchorB:cpv(-40, 40)]];
	[space add:[ChipmunkPivotJoint pivotJointWithBodyA:body11 bodyB:body12 anchorA:cpv( 40,-40) anchorB:cpv(-40,  0)]];
	
	cpFloat stiff = 30.0f;
	cpFloat damp = 1.0f;
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB: body1 anchorA:cpv(-320, 240) anchorB:cpv(-40, 40) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB: body1 anchorA:cpv(-320,  80) anchorB:cpv(-40, 40) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB: body1 anchorA:cpv(-160, 240) anchorB:cpv(-40, 40) restLength:0.0 stiffness:stiff damping:damp]];

	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB: body2 anchorA:cpv(-160, 240) anchorB:cpv( 40, 40) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB: body2 anchorA:cpv(   0, 240) anchorB:cpv( 40, 40) restLength:0.0 stiffness:stiff damping:damp]];

	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB: body3 anchorA:cpv(  80, 240) anchorB:cpv(-40, 80) restLength:0.0 stiffness:stiff damping:damp]];

	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB: body4 anchorA:cpv(  80, 240) anchorB:cpv(-40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB: body4 anchorA:cpv( 320, 240) anchorB:cpv( 40,  0) restLength:0.0 stiffness:stiff damping:damp]];

	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB: body5 anchorA:cpv(-320,  80) anchorB:cpv(-40, 40) restLength:0.0 stiffness:stiff damping:damp]];
	
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB: body9 anchorA:cpv( 320,  80) anchorB:cpv( 40, 40) restLength:0.0 stiffness:stiff damping:damp]];

	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB:body10 anchorA:cpv( 320,   0) anchorB:cpv( 40,-40) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB:body10 anchorA:cpv( 320,-160) anchorB:cpv( 40,-40) restLength:0.0 stiffness:stiff damping:damp]];

	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB:body11 anchorA:cpv(-320,-160) anchorB:cpv(-40, 40) restLength:0.0 stiffness:stiff damping:damp]];

	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB:body12 anchorA:cpv(-240,-240) anchorB:cpv(-40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB:body12 anchorA:cpv(   0,-240) anchorB:cpv( 40,  0) restLength:0.0 stiffness:stiff damping:damp]];

	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB:body13 anchorA:cpv(   0,-240) anchorB:cpv(-40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB:body13 anchorA:cpv(  80,-240) anchorB:cpv( 40,  0) restLength:0.0 stiffness:stiff damping:damp]];

	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB:body14 anchorA:cpv(  80,-240) anchorB:cpv(-40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB:body14 anchorA:cpv( 240,-240) anchorB:cpv( 40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:staticBody bodyB:body14 anchorA:cpv( 320,-160) anchorB:cpv( 40,  0) restLength:0.0 stiffness:stiff damping:damp]];

	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body1 bodyB: body5 anchorA:cpv( 40,-40) anchorB:cpv(-40, 40) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body1 bodyB: body6 anchorA:cpv( 40,-40) anchorB:cpv( 40, 40) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body2 bodyB: body3 anchorA:cpv( 40, 40) anchorB:cpv(-40, 80) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body3 bodyB: body4 anchorA:cpv(-40, 80) anchorB:cpv(-40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body3 bodyB: body4 anchorA:cpv( 40,-80) anchorB:cpv(-40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body3 bodyB: body7 anchorA:cpv( 40,-80) anchorB:cpv( 40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body3 bodyB: body7 anchorA:cpv(-40, 80) anchorB:cpv(-40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body3 bodyB: body8 anchorA:cpv( 40,-80) anchorB:cpv( 40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body3 bodyB: body9 anchorA:cpv( 40,-80) anchorB:cpv(-40,-40) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body4 bodyB: body9 anchorA:cpv( 40,  0) anchorB:cpv( 40, 40) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body5 bodyB:body11 anchorA:cpv(-40, 40) anchorB:cpv(-40, 40) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body5 bodyB:body11 anchorA:cpv( 40,-40) anchorB:cpv( 40,-40) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body7 bodyB: body8 anchorA:cpv( 40,  0) anchorB:cpv(-40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body8 bodyB:body12 anchorA:cpv(-40,  0) anchorB:cpv( 40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body8 bodyB:body13 anchorA:cpv(-40,  0) anchorB:cpv(-40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body8 bodyB:body13 anchorA:cpv( 40,  0) anchorB:cpv( 40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA: body8 bodyB:body14 anchorA:cpv( 40,  0) anchorB:cpv(-40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:body10 bodyB:body14 anchorA:cpv( 40,-40) anchorB:cpv(-40,  0) restLength:0.0 stiffness:stiff damping:damp]];
	[space add:[ChipmunkDampedSpring dampedSpringWithBodyA:body10 bodyB:body14 anchorA:cpv( 40,-40) anchorB:cpv(-40,  0) restLength:0.0 stiffness:stiff damping:damp]];
}

@end
