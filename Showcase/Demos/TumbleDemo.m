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

@interface TumbleDemo : ShowcaseDemo @end
@implementation TumbleDemo {
	ChipmunkBody *_box;
}

-(NSString *)name
{
	return @"Tumble";
}

-(NSTimeInterval)preferredTimeStep
{
	return 1.0/120.0;
}

-(void)tick:(cpFloat)dt
{
	self.space.gravity = cpvmult([Accelerometer getAcceleration], 600);
	_box.angle += _box.angVel*dt;
	
	[super tick:dt];
}

- (void)setup
{
	self.space.iterations = 5;
	
	ChipmunkBody *body;
	ChipmunkShape *shape;
	
	_box = [ChipmunkBody bodyWithMass:INFINITY andMoment:INFINITY];
	_box.angVel = 0.4;
	
	// Set up the static box.
	cpVect a = cpv(-200, -200);
	cpVect b = cpv(-200,  200);
	cpVect c = cpv( 200,  200);
	cpVect d = cpv( 200, -200);
	
	shape = [self.space add:[ChipmunkSegmentShape segmentWithBody:_box from:a to:b radius:0.0]];
	shape.elasticity = 1.0; shape.friction = 1.0;
	shape.layers = NOT_GRABABLE_MASK;

	shape = [self.space add:[ChipmunkSegmentShape segmentWithBody:_box from:b to:c radius:0.0]];
	shape.elasticity = 1.0; shape.friction = 1.0;
	shape.layers = NOT_GRABABLE_MASK;

	shape = [self.space add:[ChipmunkSegmentShape segmentWithBody:_box from:c to:d radius:0.0]];
	shape.elasticity = 1.0; shape.friction = 1.0;
	shape.layers = NOT_GRABABLE_MASK;

	shape = [self.space add:[ChipmunkSegmentShape segmentWithBody:_box from:d to:a radius:0.0]];
	shape.elasticity = 1.0; shape.friction = 1.0;
	shape.layers = NOT_GRABABLE_MASK;
	
	// Add the bricks.
	for(int i=0; i < 10; i++){
		for(int j=0; j < 10; j++){
			cpFloat width = 20;
			cpFloat height = 20;
			
			body = [self.space add:[ChipmunkBody bodyWithMass:1.0 andMoment:cpMomentForBox(1.0, width, height)]];
			body.pos = cpv(i*(width+1) - 150, j*(height+1) - 150);
			
			shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:width height:height]];
			shape.elasticity = 0.0; shape.friction = 1.0;
		}
	}
}

@end
