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

@interface PyramidToppleDemo : ShowcaseDemo @end
@implementation PyramidToppleDemo

-(NSString *)name
{
	return @"Pyramid Topple";
}

-(void)addDomino:(cpVect)pos width:(cpFloat)width height:(cpFloat)height flipped:(bool)flipped
{
	cpFloat mass = 1.0f;
	ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, width, height)]];
	body.pos = pos;
	
	
	ChipmunkShape *shape = (flipped ? [ChipmunkPolyShape boxWithBody:body width:height height:width] : [ChipmunkPolyShape boxWithBody:body width:width height:height]);
	[self.space add:shape];
	shape.elasticity = 0.0f;
	shape.friction = 0.6f;
}

-(void)setup
{
	self.space.iterations = [self numberForA4:15 A5:20];
	self.space.gravity = cpv(0, -300.0);
	self.space.sleepTimeThreshold = 0.5f;
	self.space.collisionSlop = 0.5f;
	
	// Add a floor.
	ChipmunkShape *shape = [self.space add:[ChipmunkSegmentShape segmentWithBody:self.space.staticBody from:cpv(-600, -240) to:cpv(600, -240) radius:0]];
	shape.elasticity = 1.0;
	shape.friction = 1.0;
//	shape.layers = NOT_GRABABLE_MASK;
	
	int rows = [self numberForA4:10 A5:15];
	cpFloat height = [self numberForA4:30.0 A5:20.0];
	cpFloat width = height/4.0;
	
	// Add the dominoes.
	for(int i=0; i < rows; i++){
		for(int j=0; j<(rows - i); j++){
			cpVect offset = cpv((j - (rows - 1 - i)*0.5f)*1.5f*height, (i + 0.5f)*(height + 2*width) - width - 240);
			[self addDomino:offset width:width height:height flipped:FALSE];
			[self addDomino:cpvadd(offset, cpv(0, (height + width)/2.0f)) width:width height:height flipped:TRUE];
			
			if(j == 0){
				[self addDomino:cpvadd(offset, cpv(0.5f*(width - height), height + width)) width:width height:height flipped:FALSE];
			}
			
			if(j != rows - i - 1){
				[self addDomino:cpvadd(offset, cpv(height*0.75f, (height + 3*width)/2.0f)) width:width height:height flipped:TRUE];
			} else {
				[self addDomino:cpvadd(offset, cpv(0.5f*(height - width), height + width)) width:width height:height flipped:FALSE];
			}
		}
	}
	
	{
		cpFloat radius = 10.0f;
		cpFloat mass = 5.0f;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
		body.pos = cpv(520, -180);
		body.vel = cpv(-400, 100);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
		shape.elasticity = 0.0f;
		shape.friction = 0.9f;
	}
}

-(NSTimeInterval)preferredTimeStep;
{
	return 1.0/120.0;
}

@end
