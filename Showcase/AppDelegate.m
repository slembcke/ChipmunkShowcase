#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"

#import "ViewController.h"
#import "Accelerometer.h"

#import "ShowcaseDemo.h"
#import <objc/runtime.h>

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

@synthesize demoList = _demoList;

-(void)setViewController:(ViewController *)viewController
{
//	CATransition *transition = [CATransition animation];
//	transition.duration = 0.25;
//	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//	transition.type = kCATransitionReveal;
//	transition.subtype = kCATransitionFromBottom;
//	
//	[self.window.layer addAnimation:transition forKey:nil];
	self.window.rootViewController = viewController;
}

@synthesize currentDemo = _currentDemo;
-(void)setCurrentDemo:(NSString *)currentDemo
{
	NSLog(@"Changing demo to %@", currentDemo);
	
	_currentDemo = currentDemo;
	self.viewController = [[ViewController alloc] initWithDemoClassName:currentDemo];
}

NSArray *DEMO_CLASS_NAMES = nil;

+(void)initialize
{
	DEMO_CLASS_NAMES = [NSArray arrayWithObjects:
		@"PyramidStackDemo",
		@"PyramidToppleDemo",
		@"CraneDemo",
		@"BreakableChainsDemo",
		@"TheoJansenDemo",
		@"PlanetDemo",
		@"LogoSmashDemo",
		@"PlinkDemo",
		@"TumbleDemo",
		@"BouncyTerrainDemo",
		@"MultiGrabDemo",
		nil
	];
}

-(void)nextDemo;
{
	NSUInteger index = [DEMO_CLASS_NAMES indexOfObject:self.currentDemo];
	self.currentDemo = [DEMO_CLASS_NAMES objectAtIndex:(index + 1)%[DEMO_CLASS_NAMES count]];
}

//MARK: Appdelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[Accelerometer installWithInterval:1.0/60.0 andAlpha:0.2];
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.backgroundColor = [UIColor whiteColor];
	
	self.demoList = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, self.window.bounds.size.width) style:UITableViewStylePlain];
	self.demoList.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
	self.demoList.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	self.demoList.rowHeight = 96.0;
	self.demoList.delegate = self;
	self.demoList.dataSource = self;
	
	self.currentDemo = [DEMO_CLASS_NAMES objectAtIndex:0];
	
	[ChipmunkSpace initialize];
	
	[self.window makeKeyAndVisible];
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

//MARK: Demo list table view delegate stuff

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [DEMO_CLASS_NAMES count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *identifier = @"identifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier]
		?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	
	NSString *name = [DEMO_CLASS_NAMES objectAtIndex:indexPath.row];
	ShowcaseDemo *obj = [NSClassFromString(name) alloc]; // sort of a hack, but whatever.
	
	cell.textLabel.text = obj.name;
	cell.textLabel.textColor = [UIColor whiteColor];
	cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", name]];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:FALSE];
	self.currentDemo = [DEMO_CLASS_NAMES objectAtIndex:indexPath.row];
}

@end
