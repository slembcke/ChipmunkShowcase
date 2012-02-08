#import "ShowcaseDemo.h"

@interface Template : ShowcaseDemo
@end


@implementation Template

-(NSString *)name
{
	return @"Template";
}

-(void)setup
{
}

-(void)tick:(cpFloat)dt;
{
//	self.space.gravity = cpvmult([Accelerometer getAcceleration], 300.0);
	[super tick:dt];
}

@end
