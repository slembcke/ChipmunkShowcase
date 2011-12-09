#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface ViewController : UIViewController <GLKViewControllerDelegate, GLKViewDelegate>

-(id)initWithDemoClassName:(NSString *)demo;

@end
