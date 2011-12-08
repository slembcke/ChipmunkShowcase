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
