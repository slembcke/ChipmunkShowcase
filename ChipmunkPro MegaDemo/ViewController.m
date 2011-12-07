//
//  ViewController.m
//  ChipmunkPro MegaDemo
//
//  Created by Scott Lembcke on 12/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#import "PolyRenderer.h"
#import "ChipmunkHastySpace.h"

@interface DemoSpace : ChipmunkHastySpace {
	// TODO separate renderer for static shapes?
	PolyRenderer *_renderer;
	NSMutableDictionary *_polys;
}

@end


@implementation DemoSpace

-(id)init
{
	_renderer = [[PolyRenderer alloc] init];
	_polys = [NSMutableDictionary dictionary];
	
	return [super init];
}

-(id)add:(NSObject<ChipmunkObject> *)obj;
{
	if([obj isKindOfClass:[ChipmunkPolyShape class]]){
		ChipmunkShape *shape = (id)obj;
		PolyInstance *poly = [[PolyInstance alloc] initWithShape:shape FillColor:(Color){1,0,0,1} lineColor:(Color){0,0,0,1}];
		
		shape.data = poly;
		[_polys setObject:poly forKey:[NSValue valueWithPointer:(__bridge void *)obj]];
	}
	
	return [super add:obj];
}

-(id)remove:(NSObject<ChipmunkObject> *)obj;
{
	if([obj isKindOfClass:[ChipmunkPolyShape class]]){
		[_polys removeObjectForKey:[NSValue valueWithPointer:(__bridge void *)obj]];
	}
	
	return [super remove:obj];
}

-(void)render:(Transform)projection
{
	for(ChipmunkShape *shape in self.shapes){
		cpBody *body = shape.body.body;
		cpVect pos = body->p;
		cpVect rot = body->rot;
		
		Transform t_body = {
			rot.x, -rot.y, pos.x,
			rot.y,  rot.x, pos.y,
		};

		[_renderer drawPoly:shape.data withTransform:t_mult(projection, t_body)];
	}
	
	[_renderer render];
}

@end


@interface ViewController(){
	DemoSpace *_space;
	NSMutableArray *_pentagons;
}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;
@end

@implementation ViewController

@synthesize context = _context;

-(void)awakeFromNib
{
	NSLog(@"awake");
}

-(void)viewDidLoad
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

	{
		_space = [[DemoSpace alloc] init];
		_space.iterations = 5;
		
		ChipmunkBody *staticBody = _space.staticBody;
		
		// Vertexes for a triangle shape.
		cpVect verts[] = {
			cpv(-15,-15),
			cpv(  0, 10),
			cpv( 15,-15),
		};

		// Create the static triangles.
		for(int i=0; i<9; i++){
			for(int j=0; j<6; j++){
				cpFloat stagger = (j%2)*40;
				cpVect offset = cpv(i*80 - 320 + stagger, j*70 - 240);
				ChipmunkShape *shape = [_space add:[ChipmunkPolyShape polyWithBody:staticBody count:3 verts:verts offset:offset]];
				shape.elasticity = 1.0; shape.friction = 1.0;
			}
		}
		
		_pentagons = [NSMutableArray array];
	}
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

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

#define WIDTH 1.5

-(void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
		
    glClearColor(1.0, 1.0, 1.0, 1.0);
		
		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)tearDownGL
{
	[EAGLContext setCurrentContext:self.context];
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
//	_space.gravity = cpvmult([Accelerometer getAcceleration], 100);
	_space.gravity = cpv(0.0, -100);
	
	if([_pentagons count] < 300){
		cpFloat size = 7.0;
		
		cpVect pentagon[5];
		for(int i=0; i<5; i++){
			cpFloat angle = -2*M_PI*i/5.0;
			pentagon[i] = cpv(size*cos(angle), size*sin(angle));
		}
		
		ChipmunkBody *body = [_space add:[ChipmunkBody bodyWithMass:1.0 andMoment:cpMomentForPoly(1.0, 5, pentagon, cpvzero)]];
		cpFloat x = rand()/(cpFloat)RAND_MAX*640 - 320;
		cpFloat y = rand()/(cpFloat)RAND_MAX*300 + 350;
		body.pos = cpv(x, y);
		[_pentagons addObject:body];
		
		ChipmunkShape *shape = [_space add:[ChipmunkPolyShape polyWithBody:body count:5 verts:pentagon offset:cpvzero]];
		shape.elasticity = 0.0; shape.friction = 0.4;
	}
	
	for(ChipmunkBody *body in _pentagons){
		cpVect pos = body.pos;
		if(pos.y < -260 || fabsf(pos.x) > 340){
			body.pos = cpv(((cpFloat)rand()/(cpFloat)RAND_MAX)*640.0 - 320.0, 260);
		}
	}
	
	[_space step:1.0/60.0];
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	glClear(GL_COLOR_BUFFER_BIT);
	
//	GLfloat width = 1024.0;
//	GLfloat height = 768.0;
//	Transform proj = t_ortho(cpBBNew(-512, -384, 512, 384));
	Transform proj = t_ortho(cpBBNew(-320, -240, 320, 240));
	
	[_space render:proj];
}

@end
