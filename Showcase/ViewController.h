#import <UIKit/UIKit.h>

#import "GLView.h"
#import "GLViewController.h"

@interface ViewController : UIViewController <GLViewControllerDelegate, GLViewDelegate>

-(id)initWithDemoClassName:(NSString *)demo;

@end
