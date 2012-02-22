#import <QuartzCore/QuartzCore.h>

#define CP_ALLOW_PRIVATE_ACCESS
#import "ViewController.h"

#import "AppDelegate.h"
#import "SourceViewController.h"
#import "ShowcaseDemo.h"
#import "PolyRenderer.h"

#define SLIDE_ANIMATION_DURATION 0.25
#define TITLE_ANIMATION_DURATION 0.25

#define MIN_TIMESCALE (1.0/64.0)
#define MAX_TIMESCALE 1.0

#define MIN_TIMESTEP (1.0/240.0)
#define MAX_TIMESTEP (1.0/30.0)

#define MAX_ITERATIONS 30

#define STAT_DELAY 1.0


static cpFloat
LogSliderToValue(cpFloat min, cpFloat max, cpFloat value)
{
	return min*cpfpow(max/min, value);
}

static cpFloat
ValueToLogSlider(cpFloat min, cpFloat max, cpFloat value)
{
	return logf(value/min)/logf(max/min);
}


@interface ShowcaseGLView : GLView

@property(nonatomic, assign) id touchesDelegate;

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


// Could use a better name for this.
// It's the state of the swiping stuff.
enum DemoReveal {
	DEMO_REVEAL_RIGHT,
	DEMO_REVEAL_LEFT,
	DEMO_REVEAL_NONE,
};


@interface ViewController(){
	ShowcaseDemo *_demo;
	PolyRenderer *_renderer;
	
	IBOutlet ShowcaseGLView *_glView;
	CADisplayLink *_displayLink;
	NSTimeInterval _lastTime, _lastFrameTime;
	
	IBOutlet UILabel *_demoLabel;
	
	IBOutlet UIView *_tray;
	UIView *_demoList;
	
	IBOutlet UISlider *_timeScaleSlider;
	IBOutlet UILabel *_timeScaleLabel;
	
	IBOutlet UISlider *_timeStepSlider;
	IBOutlet UILabel *_timeStepLabel;
	
	IBOutlet UISlider *_iterationsSlider;
	IBOutlet UILabel *_iterationsLabel;
	
	IBOutlet UISwitch *_drawContacts;
	
	NSTimer *_statsTimer;
	IBOutlet UITextView *_statsView;
	int _physicsTicks, _renderTicks;
}

@property(nonatomic, readonly) ShowcaseGLView *glView;

@property(nonatomic, assign) enum DemoReveal demoReveal;

-(void)setupGL;

@end



@implementation ViewController

@synthesize demoReveal = _demoReveal;
@synthesize glView = _glView;

-(id)initWithDemoClassName:(NSString *)demo
{
	NSString *nib_name = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? @"ViewController_iPhone" : @"ViewController_iPad");
	if((self = [super initWithNibName:nib_name bundle:nil])){
//	if((self = [super init])){
		_demo = [[NSClassFromString(demo) alloc] init];
		_demoReveal = DEMO_REVEAL_NONE;
	}
	
	return self;
}

//MARK: Actions

-(void)setDemoReveal:(enum DemoReveal)demoReveal
{
	NSAssert(
		_demoReveal == demoReveal || 
		_demoReveal == DEMO_REVEAL_NONE ||
		demoReveal == DEMO_REVEAL_NONE, 
		@"Cannot transition between two distinct revealed states."
	);
	
	NSArray *reveals = [NSArray arrayWithObjects:
		_tray,
		_demoList,
		nil
	];
	
	CGRect frame = self.view.bounds;
	NSArray *offsets = [NSArray arrayWithObjects:
		[NSValue valueWithCGPoint:CGPointMake(frame.origin.x - _tray.frame.size.width, 0.0)],
		[NSValue valueWithCGPoint:CGPointMake(_demoList.frame.size.width, 0.0)],
		nil
	];
	
	if(_demoReveal == DEMO_REVEAL_NONE && _demoReveal != demoReveal){
		[[reveals objectAtIndex:demoReveal] setHidden:FALSE];
		
		[self.glView setUserInteractionEnabled:FALSE];
		
		[UIView animateWithDuration:SLIDE_ANIMATION_DURATION animations:^{
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			
			CGRect frame = self.view.bounds;
			frame.origin = [[offsets objectAtIndex:demoReveal] CGPointValue];
			
			self.glView.frame = frame;
		}];
	} else if(demoReveal == DEMO_REVEAL_NONE && _demoReveal != demoReveal){
		enum DemoReveal revealToHide = _demoReveal;
		
		[UIView animateWithDuration:SLIDE_ANIMATION_DURATION animations:^{
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			self.glView.frame = self.view.bounds;
		} completion:^(BOOL finished){
			if(finished){
				[[reveals objectAtIndex:revealToHide] setHidden:TRUE];
				[self.glView setUserInteractionEnabled:TRUE];
			}
		}];
	}
	
	_demoReveal = demoReveal;
}

-(void)swipeLeft;
{
	if(self.demoReveal == DEMO_REVEAL_NONE){
		self.demoReveal = DEMO_REVEAL_RIGHT;
	} else if(self.demoReveal == DEMO_REVEAL_LEFT){
		self.demoReveal = DEMO_REVEAL_NONE;
	}
}

-(void)swipeRight;
{
	if(self.demoReveal == DEMO_REVEAL_NONE){
		self.demoReveal = DEMO_REVEAL_LEFT;
	} else if(self.demoReveal == DEMO_REVEAL_RIGHT){
		self.demoReveal = DEMO_REVEAL_NONE;
	}
}

-(void)swipeUp
{
	SourceViewController *controller = [[SourceViewController alloc] initWithDemoName:NSStringFromClass([_demo class])];
	[self presentViewController:controller animated:TRUE completion:^{}];
}

-(IBAction)timeScale:(UISlider *)slider
{
	cpFloat value = LogSliderToValue(MIN_TIMESCALE, MAX_TIMESCALE, slider.value);
	_demo.timeScale = value;
	_timeScaleLabel.text = [NSString stringWithFormat:@"Time Scale: 1:%.2f", 1.0/value];
}

-(IBAction)timeStep:(UISlider *)slider
{
	cpFloat value = LogSliderToValue(MIN_TIMESTEP, MAX_TIMESTEP, 1.0 - slider.value);
	_demo.timeStep = value;
	_timeStepLabel.text = [NSString stringWithFormat:@"Time Step: %.2f Hz", 1.0/value];
}

-(IBAction)iterations:(UISlider *)slider
{
	int value = slider.value;
	_demo.space.iterations = value;
	_iterationsLabel.text = [NSString stringWithFormat:@"Iterations: %d", value];
}

-(IBAction)reset;
{
	_demo = [[[_demo class] alloc] init];
	
	// Pump the slider data
	[self timeScale:_timeScaleSlider];
	[self timeStep:_timeStepSlider];
	[self iterations:_iterationsSlider];
	
	_physicsTicks = 0;
	_renderTicks = 0;
	
	self.glView.touchesDelegate = _demo;
	
	[self setupGL];
}

-(void)updateStats:(NSTimer *)timer
{
	cpSpace *space = _demo.space.space;
	
	// Dig out these numbers using the private API to avoid generating full lists.
	NSUInteger bodies = space->bodies->num;
	NSUInteger activeShapes = cpSpatialIndexCount(space->activeShapes);
	NSUInteger staticShapes = activeShapes + cpSpatialIndexCount(space->staticShapes);
	NSUInteger constraints = space->constraints->num;
	NSUInteger contacts = space->arbiters->num;
	
	float duration = -[(NSDate *)[timer userInfo] timeIntervalSinceNow];
	float physics = (_demo.ticks - _physicsTicks)/duration;
	float render = _renderTicks/duration;
	
	_statsView.text = [NSString stringWithFormat:
		@"Bodies: %d\n"
		@"Shapes: %d (%d)\n"
		@"Constraints: %d\n"
		@"Contacts: %d\n"
		@"Physics: %.1f Hz\n"
		@"Render: %.1f Hz\n",
		bodies, activeShapes, staticShapes, constraints, contacts, physics, render
	];
	
	_physicsTicks = _demo.ticks;
	_renderTicks = 0;
	
	[_statsTimer invalidate];
	_statsTimer = [NSTimer scheduledTimerWithTimeInterval:STAT_DELAY target:self selector:@selector(updateStats:) userInfo:[NSDate date] repeats:FALSE];
}

//MARK: Load/Unload

-(void)setupGL
{
	[self.glView runInRenderQueue:^{
		GLfloat clear = 1.0;
		glClearColor(clear, clear, clear, 1.0);

		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		
		CGSize viewSize = self.glView.bounds.size;
		Transform proj = t_mult(t_scale((viewSize.height/viewSize.width)*(4.0/3.0), 1.0), t_ortho(cpBBNew(-320, -240, 320, 240)));
		_demo.touchTransform = t_mult(t_inverse(proj), t_ortho(cpBBNew(0, viewSize.height, viewSize.width, 0)));
		
		_renderer = [[PolyRenderer alloc] initWithProjection:proj];
	} sync:TRUE];
}

- (void)tearDownGL
{
	[self.glView runInRenderQueue:^{
		NSLog(@"Tearing down GL");
		_renderer = nil;
	} sync:TRUE];
}

-(void)fadeLabel
{
	[UIView animateWithDuration:TITLE_ANIMATION_DURATION animations:^{
		_demoLabel.alpha = 0.0;
	} completion:^(BOOL completed){
		[_demoLabel removeFromSuperview];
	}];
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	if(_demo.name && _demo.showName){
		_demoLabel.text = _demo.name;
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fadeLabel) userInfo:nil repeats:NO];		
	} else {
		[_demoLabel removeFromSuperview];
	}
	
	// Set sliders to their default values
	_timeScaleSlider.value = ValueToLogSlider(MIN_TIMESCALE, MAX_TIMESCALE, 1.0);
	_timeStepSlider.value = 1.0 - ValueToLogSlider(MIN_TIMESTEP, MAX_TIMESTEP, _demo.timeStep);
	_iterationsSlider.value = _demo.space.iterations;
	[self timeScale:_timeScaleSlider];
	[self timeStep:_timeStepSlider];
	[self iterations:_iterationsSlider];
	
	_drawContacts.on = FALSE;
	
	EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	NSAssert(context, @"Failed to create ES context");
	
//	_glViewController.preferredFramesPerSecond = 60.0;
	[self.view insertSubview:self.glView belowSubview:_demoLabel];
//	[self.view addSubview:self.glView];
	self.glView.context = context;
	self.glView.touchesDelegate = _demo;
	
	// Add a nice shadow.
	self.glView.layer.shadowColor = [UIColor blackColor].CGColor;
	self.glView.layer.shadowOpacity = 1.0f;
	self.glView.layer.shadowOffset = CGSizeZero;
	self.glView.layer.shadowRadius = 15.0;
	self.glView.layer.masksToBounds = NO;
	self.glView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.glView.bounds].CGPath;
	
	AppDelegate *appDelegate = (id)[UIApplication sharedApplication].delegate;
	_demoList = appDelegate.demoList;
	_demoList.hidden = TRUE;
	[self.view insertSubview:_demoList belowSubview:self.glView];
	
	// Got weird threading crashes when these were added in a nib.
	{
		UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft)];
		swipe.direction = UISwipeGestureRecognizerDirectionLeft;
		swipe.numberOfTouchesRequired = 3;
		[self.view addGestureRecognizer:swipe];
	}{
		UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
		swipe.direction = UISwipeGestureRecognizerDirectionRight;
		swipe.numberOfTouchesRequired = 3;
		[self.view addGestureRecognizer:swipe];
	}{
		UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp)];
		swipe.direction = UISwipeGestureRecognizerDirectionUp;
		swipe.numberOfTouchesRequired = 3;
		[self.view addGestureRecognizer:swipe];
	}{
//		UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown)];
//		swipe.direction = UISwipeGestureRecognizerDirectionDown;
//		swipe.numberOfTouchesRequired = 3;
//		[self.view addGestureRecognizer:swipe];
	}
	
	// TODO add down swipe for an info pane?

	[self setupGL];
}

-(void)viewDidUnload
{    
	[super viewDidUnload];
	[self tearDownGL];
}

-(void)viewDidAppear:(BOOL)animated
{
	_statsTimer = [NSTimer scheduledTimerWithTimeInterval:STAT_DELAY target:self selector:@selector(updateStats:) userInfo:[NSDate date] repeats:FALSE];
	
	_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
	_displayLink.frameInterval = 1;
	[_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

-(void)viewDidDisappear:(BOOL)animated
{
	[_statsTimer invalidate];
	_statsTimer = nil;
	
	[_displayLink invalidate];
	_displayLink = nil;
}

-(void)dealloc
{
	[self tearDownGL];
}

//MARK: Rotation

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

#define MAX_DT (1.0/15.0)

-(void)tick:(CADisplayLink *)displayLink
{
	NSTimeInterval time = _displayLink.timestamp;
	
	NSTimeInterval dt = MIN(time - _lastTime, MAX_DT);
	[_demo update:dt];
	
	BOOL needs_sync = (time - _lastFrameTime > MAX_DT);
	if(!_glView.isRendering || needs_sync){
		if(needs_sync) [_glView sync];
		[_demo render:_renderer showContacts:_drawContacts.on];
		
		[_glView display:^{
			[_glView clear];
			[_renderer render];
		} sync:needs_sync];
		
		_renderTicks++;
		_lastFrameTime = time;
	}
	
	_lastTime = time;
}

@end
