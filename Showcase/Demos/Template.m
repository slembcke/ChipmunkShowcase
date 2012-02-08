#import "ShowcaseDemo.h"

@interface Template : ShowcaseDemo @end
@implementation Template

-(NSString *)name
{
	return @"Template";
}

-(void)setup
{
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
