#import "ShowcaseDemo.h"

@interface Template : ShowcaseDemo @end
@implementation Template

-(NSString *)name
{
	return @"Template";
}

-(void)setup
{
//	CGRect bounds = CGRectMake(-320, -240, 640, 480);
//	[self.space addBounds:bounds thickness:10.0 elasticity:1.0 friction:1.0 layers:NOT_GRABABLE_MASK group:nil collisionType:nil];
}

//-(NSTimeInterval)fixedDt;
//{
//	return 1.0/60.0;
//}

//-(void)tick:(cpFloat)dt;
//{
//	self.space.gravity = cpvmult([Accelerometer getAcceleration], 300.0);
//	[super tick:dt];
//}

@end
