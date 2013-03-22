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

@interface PyramidStackDemo : ShowcaseDemo @end
@implementation PyramidStackDemo

-(NSString *)name
{
	return @"Pyramid Stack";
}

-(void)setup
{
	self.space.gravity = cpv(0, -100.0f);
	self.space.iterations = 30;
	self.space.sleepTimeThreshold = 0.5f;
	self.space.collisionSlop = 0.5f;
	
	CGRect bounds = self.demoBounds;
	bounds.size.height = bounds.size.width;
	[self.space addBounds:bounds thickness:10.0 elasticity:1.0 friction:1.0 layers:NOT_GRABABLE_MASK group:nil collisionType:nil];
	
	NSUInteger height = [self numberForA4:14 A5:25 A6:31];
	cpFloat size = [self numberForA4:28.0 A5:20.0 A6:18.0];
	
	for(int i=0; i < height; i++){
		for(int j=0; j<=i; j++){
			cpFloat mass = 2.0;
			
			cpFloat spacing = size + 2.0;
			
			ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, size, size)]];
			body.pos = cpv((j - i/2.0)*spacing, -200 + (height - i - 1)*spacing);
			
			ChipmunkShape *shape = [self.space add:[ChipmunkPolyShape boxWithBody:body width:size height:size]];
			shape.elasticity = 0.0;
			shape.friction = 0.8f;
		}
	}
	
	// Add a ball to make things more interesting
	{
		cpFloat radius = 10.0f;
		cpFloat mass = 20.0f;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
		body.pos = cpv(0, -240 + radius+5);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
		shape.elasticity = 0.0f;
		shape.friction = 0.9f;
	}
}

-(NSTimeInterval)preferredTimeStep
{
	return 1.0/60.0;
}

@end
