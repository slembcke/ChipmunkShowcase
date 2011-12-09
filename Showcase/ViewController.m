#define CP_ALLOW_PRIVATE_ACCESS

#import "ViewController.h"

#import "ShowcaseDemo.h"
#import "PolyRenderer.h"

@interface ShowcaseGLView : GLKView {
	__weak id _touchesDelegate;
}

@property(nonatomic, weak) id touchesDelegate;

@end


@implementation ShowcaseGLView

@synthesize touchesDelegate = _touchesDelegate;

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	[_touchesDelegate touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	[_touchesDelegate touchesMoved:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
	[_touchesDelegate touchesEnded:touches withEvent:event];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[_touchesDelegate touchesCancelled:touches withEvent:event];
}

@end


@interface ViewController(){
	ShowcaseDemo *_demo;
	
	PolyRenderer *_staticRenderer;
	PolyRenderer *_renderer;
}

@property(strong, nonatomic) EAGLContext *context;

@end


@implementation ViewController

@synthesize context = _context;

-(id)initWithDemoClassName:(NSString *)demo
{
	NSString *nib_name = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? @"ViewController_iPhone" : @"ViewController_iPad");
	if((self = [super initWithNibName:nib_name bundle:nil])){
		_demo = [[NSClassFromString(@"BouncyTerrainDemo") alloc] init];
	}
	
	return self;
}

-(void)setupGL
{
	[EAGLContext setCurrentContext:self.context];

	GLfloat clear = 1.0;
	glClearColor(clear, clear, clear, 1.0);

	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

	Transform proj = t_ortho(cpBBNew(-320, -240, 320, 240));
	
//	CGSize viewSize = self.view.frame.size; // TODO why does this return 768x1004??
	_demo.touchTransform = t_inverse(t_mult(t_inverse(t_ortho(cpBBNew(0, 768, 1024, 0))), proj));
	
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

	self.preferredFramesPerSecond = 60;
	
	self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	if (!self.context) {
		NSLog(@"Failed to create ES context");
	}

	ShowcaseGLView *view = (ShowcaseGLView *)self.view;
	view.multipleTouchEnabled = TRUE;
	view.drawableColorFormat = GLKViewDrawableColorFormatRGB565;
	view.context = self.context;
	view.touchesDelegate = _demo;
	
	id appDelegate = [UIApplication sharedApplication].delegate;
	UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:appDelegate action:@selector(nextDemo:)];
	swipe.numberOfTouchesRequired = 4;
	
	[view addGestureRecognizer:swipe];

	[self setupGL];
}

- (void)tearDownGL
{
	[EAGLContext setCurrentContext:self.context];
	
	_staticRenderer = nil;
	_renderer = nil;
}

-(void)viewDidUnload
{    
	[super viewDidUnload];

	[self tearDownGL];

	if([EAGLContext currentContext] == self.context) {
		[EAGLContext setCurrentContext:nil];
	}
	
	self.context = nil;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

//MARK: GLKView and GLKViewController delegate methods

- (void)update
{
	[_demo update:self.timeSinceLastUpdate];
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	glClear(GL_COLOR_BUFFER_BIT);
	
	// TODO interpolated rendering?
	[_demo render:_renderer timeSinceLastUpdate:self.timeSinceLastUpdate];
	[_renderer render];
	
	[_staticRenderer renderStatic];
	
	GLenum err;
	while((err = glGetError())) NSLog(@"GLError %X", err);
}

@end
