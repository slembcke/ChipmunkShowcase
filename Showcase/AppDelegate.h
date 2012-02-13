#import <UIKit/UIKit.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, strong) ViewController *viewController;

@property(nonatomic, strong) UITableView *demoList;
@property(nonatomic, strong) NSString *currentDemo;

-(void)nextDemo;

@end
