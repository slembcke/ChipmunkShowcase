#define CP_ALLOW_PRIVATE_ACCESS

#import "ShowcaseDemo.h"

#import "ObjectiveChipmunk.h"
#import "ChipmunkHastySpace.h"
#import "PolyRenderer.h"


// Space subclass that creates/tracks polys for the rendering
@interface DemoSpace : ChipmunkHastySpace {
	NSMutableDictionary *_polys;
}

@end


@implementation DemoSpace

-(id)init
{
	if((self = [super init])){
		_polys = [NSMutableDictionary dictionary];
	}
	
	return self;
}

-(id)add:(NSObject<ChipmunkObject> *)obj;
{
	if([obj isKindOfClass:[ChipmunkShape class]]){
		ChipmunkShape *shape = (id)obj;
		
		Color line = {0,0,0,1};
		Color fill = {};
		[[UIColor colorWithHue:frand() saturation:1.0 brightness:0.8 alpha:1.0] getRed:&fill.r green:&fill.g blue:&fill.b alpha:&fill.a];
		
		PolyInstance *poly = [[PolyInstance alloc] initWithShape:shape width:1.0 FillColor:fill lineColor:line];
		if(poly){
			shape.data = poly;
			[_polys setObject:poly forKey:[NSValue valueWithPointer:(__bridge void *)obj]];
		}
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

@end


@interface ShowcaseDemo(){
	DemoSpace *_space;
	
	ChipmunkMultiGrab *_multiGrab;
	
	// Convert touches to absolute coords.
	Transform _touchTransform;
	
	NSTimeInterval _accumulator;
	NSTimeInterval _fixedTime;
}

@end


@implementation ShowcaseDemo

@dynamic name;

-(BOOL)showName
{
	return TRUE;
}

@synthesize touchTransform = _touchTransform;

@synthesize space = _space;

@synthesize ticks = _ticks;
@synthesize accumulator = _accumulator;
@synthesize timeScale = _timeScale;

@synthesize timeStep = _timeStep;

-(ChipmunkBody *)staticBody
{
	return _space.staticBody;
}

-(void)setup {}

-(id)init
{
	if((self = [super init])){
		_space = [[DemoSpace alloc] init];
		_multiGrab = [[ChipmunkMultiGrab alloc] initForSpace:self.space withSmoothing:cpfpow(0.8, 60) withGrabForce:1e5];
		_multiGrab.layers = GRABABLE_MASK_BIT;
		
		_timeScale = 1.0;
		_timeStep = self.preferredTimeStep;
		
		[self setup];
	}
	
	return self;
}

-(NSTimeInterval)preferredTimeStep;
{
	return 1.0/60.0;
}

-(void)tick:(cpFloat)dt {
	[self.space step:dt];
	_ticks++;
}

-(void)update:(NSTimeInterval)dt
{
	NSTimeInterval fixed_dt = _timeStep;
	
	_accumulator += dt*self.timeScale;
	while(_accumulator > fixed_dt){
		[self tick:fixed_dt];
		_accumulator -= fixed_dt;
		_fixedTime += fixed_dt;
	}
}

//MARK: Rendering

static inline Transform
t_shape(ChipmunkShape *shape, cpFloat extrapolate)
{
	cpBody *body = shape.body.body;
	cpVect pos = cpvadd(body->p, cpvmult(body->v, extrapolate));;
	cpVect rot = cpvrotate(body->rot, cpvforangle(body->w*extrapolate));
	
	return (Transform){
		rot.x, -rot.y, pos.x,
		rot.y,  rot.x, pos.y,
	};
}

-(void)prepareStaticRenderer:(PolyRenderer *)renderer;
{
	for(ChipmunkShape *shape in _space.shapes){
		if(shape.body.isStatic) [renderer drawPoly:shape.data withTransform:t_shape(shape, 0.0)];
	}
}

-(void)render:(PolyRenderer *)renderer showContacts:(BOOL)showContacts;
{
	for(ChipmunkShape *shape in _space.shapes){
		if(!shape.body.isStatic) [renderer drawPoly:shape.data withTransform:t_shape(shape, _accumulator)];
	}
	
	if(showContacts){
		// This is using the private API to efficiently render the collision points.
		// Don't do this in a real game!
		cpArray *arbiters = _space.space->arbiters;
		for(int i=0; i<arbiters->num; i++){
			cpArbiter *arb = (cpArbiter*)arbiters->arr[i];
			
			for(int i=0; i<arb->numContacts; i++){
				[renderer drawDot:arb->contacts[i].p radius:2.0 color:(Color){1,0,0,1}];
			}
		}
	}
}

//MARK: Input

-(cpVect)convertTouch:(UITouch *)touch;
{
	return t_point(_touchTransform, [touch locationInView:touch.view]);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for(UITouch *touch in touches){
		[_multiGrab beginLocation:[self convertTouch:touch]];
	}
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for(UITouch *touch in touches){
		[_multiGrab updateLocation:[self convertTouch:touch]];
	}
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for(UITouch *touch in touches){
		[_multiGrab endLocation:[self convertTouch:touch]];
	}
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEnded:touches withEvent:event];
}


@end
