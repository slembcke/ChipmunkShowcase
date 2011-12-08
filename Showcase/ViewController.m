#define CP_ALLOW_PRIVATE_ACCESS

#import "ViewController.h"

#import "ShowcaseDemo.h"
#import "PolyRenderer.h"

@interface ViewController(){
	ShowcaseDemo *_demo;
	
	PolyRenderer *_staticRenderer;
	PolyRenderer *_renderer;
}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation ViewController

@synthesize context = _context;

-(void)viewDidLoad
{
	[super viewDidLoad];

	self.preferredFramesPerSecond = 60;

	_demo = [[ShowcaseDemo alloc] init]; // TODO should be passed in fully initialized already
	
	self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	if (!self.context) {
		NSLog(@"Failed to create ES context");
	}

	GLKView *view = (GLKView *)self.view;
	view.drawableColorFormat = GLKViewDrawableColorFormatRGB565;
	view.context = self.context;

	[self setupGL];
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
	return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

-(void)setupGL
{
	[EAGLContext setCurrentContext:self.context];

	GLfloat clear = 1.0;
	glClearColor(clear, clear, clear, 1.0);

	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

//	GLfloat width = 1024.0;
//	GLfloat height = 768.0;
//	Transform proj = t_ortho(cpBBNew(-512, -384, 512, 384));
	Transform proj = t_ortho(cpBBNew(-320, -240, 320, 240));
	
	_staticRenderer = [[PolyRenderer alloc] init];
	_renderer = [[PolyRenderer alloc] init];
	
	_staticRenderer.projection = proj;
	_renderer.projection = proj;
	
	[_demo prepareStaticRenderer:_staticRenderer];
	[_staticRenderer prepareStatic];
}

- (void)tearDownGL
{
	[EAGLContext setCurrentContext:self.context];
	
	_staticRenderer = nil;
	_renderer = nil;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
	[_demo update:self.timeSinceLastUpdate];
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	glClear(GL_COLOR_BUFFER_BIT);
	
	// TODO interpolated rendering?
	[_demo render:_renderer];
	[_renderer render];
	
	[_staticRenderer renderStatic];
	
	GLenum err;
	while((err = glGetError())) NSLog(@"GLError %X", err);
}

@end
