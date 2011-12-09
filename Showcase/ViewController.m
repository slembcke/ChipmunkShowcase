#define CP_ALLOW_PRIVATE_ACCESS
#import "ViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"
#import "ShowcaseDemo.h"
#import "PolyRenderer.h"

@interface FuckViews : UIView
@end

@interface ShowcaseGLView : GLKView {
	__weak id _touchesDelegate;
}

@property(nonatomic, weak) id touchesDelegate;

@end


@implementation ShowcaseGLView

@synthesize touchesDelegate = _touchesDelegate;

//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
//{
//	[_touchesDelegate touchesBegan:touches withEvent:event];
//}
//
//-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
//{
//	[_touchesDelegate touchesMoved:touches withEvent:event];
//}
//
//-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
//{
//	[_touchesDelegate touchesEnded:touches withEvent:event];
//}
//
//-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
//{
//	[_touchesDelegate touchesCancelled:touches withEvent:event];
//}

@end


@interface ViewController(){
	ShowcaseDemo *_demo;
	
	EAGLContext *_context;
	PolyRenderer *_staticRenderer;
	PolyRenderer *_renderer;
	
	IBOutlet GLKViewController *_glkViewController;
	IBOutlet UIView *_tray;
}

@property(nonatomic, readonly) ShowcaseGLView *glView;

@end



@implementation ViewController

-(ShowcaseGLView *)glView
{
	return (ShowcaseGLView *)[_glkViewController view];
}

-(id)initWithDemoClassName:(NSString *)demo
{
	NSString *nib_name = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? @"ViewController_iPhone" : @"ViewController_iPad");
	if((self = [super initWithNibName:nib_name bundle:nil])){
//	if((self = [super init])){
		_demo = [[NSClassFromString(demo) alloc] init];
	}
	
	return self;
}

//MARK: Actions

-(IBAction)nextDemo:(id)sender;
{
	[(AppDelegate *)[UIApplication sharedApplication].delegate nextDemo];
}

-(IBAction)openTray:(id)sender;
{
	_tray.hidden = FALSE;
	[self.glView setUserInteractionEnabled:FALSE];
	_glkViewController.paused = TRUE;
	
	[UIView animateWithDuration:0.5 animations:^{
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		
		CGRect frame = self.view.bounds;
		frame.origin.x -= _tray.frame.size.width;
		
		self.glView.frame = frame;
	}];
}

-(IBAction)closeTray:(id)sender;
{
	[UIView animateWithDuration:0.5 animations:^{
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		self.glView.frame = self.view.bounds;
	} completion:^(BOOL finished){
		if(finished){
			_tray.hidden = TRUE;
			[self.glView setUserInteractionEnabled:TRUE];
			_glkViewController.paused = FALSE;
		}
	}];
}

//MARK: Load/Unload

-(void)loadView
{
	[super loadView];
	
	self.view.backgroundColor = [UIColor magentaColor];
}

-(void)setupGL
{
	[EAGLContext setCurrentContext:_context];

	GLfloat clear = 1.0;
	glClearColor(clear, clear, clear, 1.0);

	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	Transform proj = t_ortho(cpBBNew(-320, -240, 320, 240));
	proj = t_mult(t_scale(8.0/9.0, 1.0), proj);
	
	CGSize viewSize = self.glView.bounds.size;
	NSLog(@"View size: %@", NSStringFromCGSize(viewSize)); 
	_demo.touchTransform = t_inverse(t_mult(t_inverse(t_ortho(cpBBNew(0, 768, 1024, 0))), proj));
	
	// TODO initializer should take a projection
	_staticRenderer = [[PolyRenderer alloc] init];
	_renderer = [[PolyRenderer alloc] init];
	
	_staticRenderer.projection = proj;
	_renderer.projection = proj;
	
	[_demo prepareStaticRenderer:_staticRenderer];
	[_staticRenderer prepareStatic];
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	NSAssert(_context, @"Failed to create ES context");

//	_glkViewController = [[GLKViewController alloc] init];
//	_glkViewController.view = [[ShowcaseGLView alloc] initWithFrame:self.view.bounds context:self.context];
//	_glkViewController.preferredFramesPerSecond = 60;
//	_glkViewController.delegate = self;
	
//	self.glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//	self.glView.delegate = self;
//	self.glView.backgroundColor = [UIColor whiteColor];
//	self.glView.multipleTouchEnabled = TRUE;
//	self.glView.drawableColorFormat = GLKViewDrawableColorFormatRGB565;
	self.glView.context = _context;
	self.glView.touchesDelegate = _demo;
//	[self.view addSubview:self.glView];
	
//	{
//		id appDelegate = [UIApplication sharedApplication].delegate;
//		UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:appDelegate action:@selector(nextDemo)];
//		swipe.numberOfTouchesRequired = 1;
//		swipe.direction = UISwipeGestureRecognizerDirectionRight;
//		[self.glView addGestureRecognizer:swipe];
//	}{
//		UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showTray)];
//		swipe.numberOfTouchesRequired = 1;
//		swipe.direction = UISwipeGestureRecognizerDirectionLeft;
//		[self.glView addGestureRecognizer:swipe];
//	}

	[self setupGL];
}

- (void)tearDownGL
{
	[EAGLContext setCurrentContext:_context];
	
	_staticRenderer = nil;
	_renderer = nil;
}

-(void)viewDidUnload
{    
	[super viewDidUnload];

	[self tearDownGL];

	if([EAGLContext currentContext] == _context){
		[EAGLContext setCurrentContext:nil];
	}
	
	_context = nil;
}

//MARK: Rotation

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

//MARK: GLKView and GLKViewController delegate methods

-(void)glkViewControllerUpdate:(GLKViewController *)controller
{
	[_demo update:_glkViewController.timeSinceLastUpdate];
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	NSAssert([EAGLContext currentContext] == _context, @"Wrong context set?");
	glClear(GL_COLOR_BUFFER_BIT);
	
	[_staticRenderer renderStatic];
	
	[_demo render:_renderer timeSinceLastUpdate:_glkViewController.timeSinceLastUpdate];
	[_renderer render];
	
	PRINT_GL_ERRORS();
}

@end
