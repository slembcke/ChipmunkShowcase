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

#import "Accelerometer.h"

@implementation Accelerometer

static Accelerometer *shared_instance = nil;
static float alpha = 1.0f;
static cpVect accel = {};

+ (void)initialize {
	static bool done = FALSE;
	if(done) return;
	
	NSLog(@"Creating shared accelerometer");
	shared_instance = [[self alloc] init];
	
	done = TRUE;
}

+ (void)installWithInterval:(NSTimeInterval)interval andAlpha:(float)alphaValue {
	NSLog(@"Installing accelerometer delegate");
	alpha = alphaValue;
	
	UIAccelerometer *meter = [UIAccelerometer sharedAccelerometer];
	meter.delegate = shared_instance;
	meter.updateInterval = interval;
}

+ (cpVect)getAcceleration {
	return accel;
}

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)a {
	accel = cpvlerp(accel, cpv(-a.y, a.x), alpha);
}

@end
