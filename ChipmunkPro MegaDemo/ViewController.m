//
//  ViewController.m
//  ChipmunkPro MegaDemo
//
//  Created by Scott Lembcke on 12/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#import "PolyRenderer.h"


@interface ViewController(){
	PolyInstance *_instance;
	PolyRenderer *_renderer;
}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;
@end

@implementation ViewController

@synthesize context = _context;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
		self.preferredFramesPerSecond = 60;
		
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
		view.drawableColorFormat = GLKViewDrawableColorFormatRGB565;
    view.context = self.context;
    
    [self setupGL];
		
		Color fill = {1.0, 0.0, 0.0, 1.0};
		Color line = {0.0, 0.0, 0.0, 1.0};
		_instance = [[PolyInstance alloc] initWithFillColor:fill lineColor:line];
		_renderer = [[PolyRenderer alloc] init];
}

- (void)viewDidUnload
{    
	[super viewDidUnload];

	[self tearDownGL];

	if([EAGLContext currentContext] == self.context) {
		[EAGLContext setCurrentContext:nil];
	}
	
	self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

#define WIDTH 1.5

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
		
    glClearColor(1.0, 1.0, 1.0, 1.0);
		
		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)tearDownGL
{
	[EAGLContext setCurrentContext:self.context];
	_renderer = nil;
}

#pragma mark - GLKView and GLKViewController delegate methods

static inline cpFloat frand(){return (cpFloat)rand()/(cpFloat)RAND_MAX;}

- (void)update
{
	// TODO physics!
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	glClear(GL_COLOR_BUFFER_BIT);
	
	GLfloat width = 1024.0;
	GLfloat height = 768.0;
	
	Transform proj = t_ortho(cpBBNew(0.0, 0.0, width, height));
	
	cpFloat time = self.timeSinceLastResume;
	
	srand(987434);
	for(int i=0; i<500; i++){
		cpVect pos = cpv(width*frand(), height*frand());
		cpVect rot = cpvforangle((frand()*2.0 - 1.0)*time*3.0);
		
		Transform t = {
			rot.x, -rot.y, pos.x,
			rot.y,  rot.x, pos.y,
		};
		t = t_wrap(t_translate(cpv(0.0, -50.0)), t);
		
		[_renderer drawPoly:_instance withTransform:t_mult(proj, t)];
	}

	[_renderer render];
}

@end
