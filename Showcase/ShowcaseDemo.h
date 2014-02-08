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

#import "PolyRenderer.h"
#import "Accelerometer.h"

@interface ChipmunkShape(DemoRenderer)

-(Color)color;

@end

#define GRABABLE_MASK_BIT (1<<31)
#define NOT_GRABABLE_MASK (~GRABABLE_MASK_BIT)

@interface ShowcaseDemo : NSObject

@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) BOOL showName;

@property(nonatomic, strong) ChipmunkSpace *space;
@property(nonatomic, readonly) ChipmunkBody *staticBody;

@property(nonatomic, assign) cpTransform touchTransform;

@property(nonatomic, readonly) NSUInteger ticks;
@property(nonatomic, readonly) NSTimeInterval fixedTime;
@property(nonatomic, readonly) NSTimeInterval renderTime;
@property(nonatomic, readonly) NSTimeInterval accumulator;
@property(nonatomic, assign) cpFloat timeScale;

@property(nonatomic, readonly) NSTimeInterval preferredTimeStep;
@property(nonatomic, assign) NSTimeInterval timeStep;

// Override this method if you want to use a custom ChipmunkSpace class.
// Returns ChipmunkHastySpace by default.
-(Class)spaceClass;

// Tune for CPU and iPhone/iPad
-(float)numberForA4:(float)A4 A5:(float)A5 A6:(float)A6;
-(cpBB)demoBounds;

-(void)update:(NSTimeInterval)dt;
-(void)tick:(cpFloat)dt;

-(void)render:(PolyRenderer *)renderer showContacts:(BOOL)showContacts;

//Mark: Input

-(cpVect)convertTouch:(UITouch *)touch;

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end

//MARK: Utility Methods

static inline cpFloat
frand(void)
{
	return (cpFloat)rand()/(cpFloat)RAND_MAX;
}

static cpVect
frand_unit_circle()
{
	cpVect v = cpv(frand()*2.0f - 1.0f, frand()*2.0f - 1.0f);
	return (cpvlengthsq(v) < 1.0f ? v : frand_unit_circle());
}


#define SHAPE_OUTLINE_WIDTH 1.0
#define SHAPE_OUTLINE_COLOR ((Color){200.0/255.0, 210.0/255.0, 230.0/255.0, 1.0})

#define CONTACT_COLOR ((Color){1.0, 0.0, 0.0, 1.0})

#define CONSTRAINT_DOT_RADIUS 3.0
#define CONSTRAINT_LINE_RADIUS 1.0
#define CONSTRAINT_COLOR ((Color){0.0, 0.75, 0.0, 1.0})
