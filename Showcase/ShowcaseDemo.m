#define CP_ALLOW_PRIVATE_ACCESS

#import "ShowcaseDemo.h"

#import "ObjectiveChipmunk.h"
#import "ChipmunkHastySpace.h"
#import "PolyRenderer.h"

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

static Color
ColorFromHash(cpHashValue hash, float alpha)
{
	unsigned long val = (unsigned long)hash;
	
	// scramble the bits up using Robert Jenkins' 32 bit integer hash function
	val = (val+0x7ed55d16) + (val<<12);
	val = (val^0xc761c23c) ^ (val>>19);
	val = (val+0x165667b1) + (val<<5);
	val = (val+0xd3a2646c) ^ (val<<9);
	val = (val+0xfd7046c5) + (val<<3);
	val = (val^0xb55a4f09) ^ (val>>16);
	
	GLfloat r = (val>>0) & 0xFF;
	GLfloat g = (val>>8) & 0xFF;
	GLfloat b = (val>>16) & 0xFF;
	
	GLfloat max = MAX(MAX(r, g), b);
	
	// saturate and scale the colors
	const GLfloat mult = 1.0;
	const GLfloat add = 0.0;
	
	return (Color){
		(r*mult)/max + add,
		(g*mult)/max + add,
		(b*mult)/max + add,
		alpha
	};
}

Color ColorBlack = {0.0, 0.0, 0.0, 1.0};


@interface ChipmunkShape(DemoRenderer)

-(PolyInstance *)polyInstanceWithWidth:(cpFloat)width fillColor:(Color)fill lineColor:(Color)line;
-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;

-(Color)color;

@end

@implementation ChipmunkShape(DemoRenderer)

-(PolyInstance *)polyInstanceWithWidth:(cpFloat)width fillColor:(Color)fill lineColor:(Color)line
{
	return nil;
}

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
}

-(Color)color
{
	ChipmunkBody *body = self.body;
	
	if(body.isSleeping){
		return (Color){0.5, 0.5, 0.5, 1.0};
	} else {
		return ColorFromHash(self.shape->hashid, 1.0);
	}
}

@end


@implementation ChipmunkCircleShape(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
//	[renderer drawPoly:self.data withTransform:t_shape(self, dt)];
}

-(PolyInstance *)polyInstanceWithWidth:(cpFloat)width fillColor:(Color)fill lineColor:(Color)line
{
	return [[PolyInstance alloc] initWithCircleShape:self width:width fillColor:fill lineColor:line];
}

@end


@implementation ChipmunkSegmentShape(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	ChipmunkBody *body = self.body;
	cpVect a = [body local2world:self.a];
	cpVect b = [body local2world:self.b];
	[renderer drawSegmentFrom:a to:b radius:1.0 color:ColorBlack];
}

-(PolyInstance *)polyInstanceWithWidth:(cpFloat)width fillColor:(Color)fill lineColor:(Color)line
{
	return [[PolyInstance alloc] initWithSegmentShape:self width:width fillColor:fill lineColor:line];
}

@end


@implementation ChipmunkPolyShape(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer dt:(cpFloat)dt;
{
	cpPolyShape *poly = (cpPolyShape *)self.shape;
	[renderer drawPolyWithVerts:poly->tVerts count:poly->numVerts width:1.0 fill:self.color line:ColorBlack];
}

-(PolyInstance *)polyInstanceWithWidth:(cpFloat)width fillColor:(Color)fill lineColor:(Color)line
{
	return [[PolyInstance alloc] initWithPolyShape:self width:width fillColor:fill lineColor:line];
}

@end


#define CONSTRAINT_DOT_RADIUS 3.0
#define CONSTRAINT_LINE_RADIUS 1.0

Color CONSTRAINT_COLOR = (Color){0.0, 0.5, 0.0, 1.0};

@interface ChipmunkConstraint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer;

@end


@implementation ChipmunkConstraint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer {}

@end


@implementation ChipmunkPinJoint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer
{
	cpVect a = [self.bodyA local2world:self.anchr1];
	cpVect b = [self.bodyB local2world:self.anchr2];
	
	[renderer drawDot:a radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:b radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawSegmentFrom:a to:b radius:CONSTRAINT_LINE_RADIUS color:CONSTRAINT_COLOR];
}

@end


@implementation ChipmunkSlideJoint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer
{
	cpVect a = [self.bodyA local2world:self.anchr1];
	cpVect b = [self.bodyB local2world:self.anchr2];
	
	[renderer drawDot:a radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:b radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawSegmentFrom:a to:b radius:CONSTRAINT_LINE_RADIUS color:CONSTRAINT_COLOR];
}

@end


@implementation ChipmunkPivotJoint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer
{
	cpVect a = [self.bodyA local2world:self.anchr1];
	cpVect b = [self.bodyB local2world:self.anchr2];
	
	[renderer drawDot:a radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:b radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
}

@end


@implementation ChipmunkGrooveJoint(DemoRenderer)

-(void)drawWithRenderer:(PolyRenderer *)renderer
{
	// Hmm apparently I never made the groove joint properties...
	cpVect a = [self.bodyA local2world:cpGrooveJointGetGrooveA(self.constraint)];
	cpVect b = [self.bodyA local2world:cpGrooveJointGetGrooveB(self.constraint)];
	cpVect c = [self.bodyB local2world:cpGrooveJointGetAnchr2(self.constraint)];
	
	[renderer drawSegmentFrom:a to:b radius:CONSTRAINT_LINE_RADIUS color:CONSTRAINT_COLOR];
	[renderer drawDot:c radius:CONSTRAINT_DOT_RADIUS color:CONSTRAINT_COLOR];
}

@end

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
		
		PolyInstance *poly = [shape polyInstanceWithWidth:1.0 fillColor:fill lineColor:line];
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

-(void)prepareStaticRenderer:(PolyRenderer *)renderer;
{
//	for(ChipmunkShape *shape in _space.shapes){
//		if(shape.body.isStatic) [renderer drawPoly:shape.data withTransform:t_shape(shape, 0.0)];
//	}
}

-(void)render:(PolyRenderer *)renderer showContacts:(BOOL)showContacts;
{
	for(ChipmunkShape *shape in _space.shapes){
		//if(!shape.body.isStatic) [renderer drawPoly:shape.data withTransform:t_shape(shape, _accumulator)];
		//[renderer drawPoly:shape.data withTransform:t_shape(shape, _accumulator)];
		[shape drawWithRenderer:renderer dt:_accumulator];
	}
	
	for(ChipmunkConstraint *constraint in _space.constraints){
		[constraint drawWithRenderer:renderer];
	}
	
	if(showContacts){
		// This is using the private API to efficiently render the collision points.
		// Don't do this in a real game!
		cpArray *arbiters = _space.space->arbiters;
		for(int i=0; i<arbiters->num; i++){
			cpArbiter *arb = (cpArbiter*)arbiters->arr[i];
			
			for(int i=0; i<arb->numContacts; i++){
				[renderer drawDot:arb->contacts[i].p radius:2.5 color:(Color){1,0,0,1}];
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
