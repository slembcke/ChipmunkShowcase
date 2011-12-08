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
	_polys = [NSMutableDictionary dictionary];
	return [super init];
}

static inline cpFloat frand(void){return (cpFloat)rand()/(cpFloat)RAND_MAX;}

-(id)add:(NSObject<ChipmunkObject> *)obj;
{
	if([obj isKindOfClass:[ChipmunkPolyShape class]]){
		ChipmunkShape *shape = (id)obj;
		
		Color line = {0,0,0,1};
		Color fill = {};
		[[UIColor colorWithHue:frand() saturation:1.0 brightness:0.8 alpha:1.0] getRed:&fill.r green:&fill.g blue:&fill.b alpha:&fill.a];
		
		PolyInstance *poly = [[PolyInstance alloc] initWithShape:shape width:1.0 FillColor:fill lineColor:line];
		
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

@end


@interface ShowcaseDemo(){
	DemoSpace *_space;
	
	ChipmunkMultiGrab *_multiGrab;
	// Convert touches to absolute coords.
	Transform _touchTransform;
}

@end


@implementation ShowcaseDemo

@synthesize touchTransform = _touchTransform;


-(id)init
{
	if((self = [super init])){
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
				shape.layers = NOT_GRABABLE_MASK;
			}
		}
		
		_multiGrab = [[ChipmunkMultiGrab alloc] initForSpace:_space withSmoothing:cpfpow(0.8, 60) withGrabForce:1e4];
		_multiGrab.layers = GRABABLE_MASK_BIT;
	}
	
	return self;
}

-(void)update:(NSTimeInterval)dt;
{
//	_space.gravity = cpvmult([Accelerometer getAcceleration], 100);
	_space.gravity = cpv(0.0, -100);
	
	NSArray *bodies = _space.bodies;
	if([bodies count] < 450){
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
		
		ChipmunkShape *shape = [_space add:[ChipmunkPolyShape polyWithBody:body count:5 verts:pentagon offset:cpvzero]];
		shape.elasticity = 0.0; shape.friction = 0.4;
	}
	
	for(ChipmunkBody *body in bodies){
		cpVect pos = body.pos;
		if(pos.y < -260 || fabsf(pos.x) > 340){
			body.pos = cpv(((cpFloat)rand()/(cpFloat)RAND_MAX)*640.0 - 320.0, 260);
		}
	}
	
	[_space step:1.0/60.0];
}

//MARK: Rendering

static inline Transform
t_shape(ChipmunkShape *shape)
{
	cpBody *body = shape.body.body;
	cpVect pos = body->p;
	cpVect rot = body->rot;
	
	return (Transform){
		rot.x, -rot.y, pos.x,
		rot.y,  rot.x, pos.y,
	};
}

-(void)prepareStaticRenderer:(PolyRenderer *)renderer;
{
	for(ChipmunkShape *shape in _space.shapes){
		if(shape.body.isStatic) [renderer drawPoly:shape.data withTransform:t_shape(shape)];
	}
}

-(void)render:(PolyRenderer *)renderer
{
	for(ChipmunkShape *shape in _space.shapes){
		if(!shape.body.isStatic) [renderer drawPoly:shape.data withTransform:t_shape(shape)];
	}
	
	cpArray *arbiters = _space.space->arbiters;
	for(int i=0; i<arbiters->num; i++){
		cpArbiter *arb = (cpArbiter*)arbiters->arr[i];
		
		for(int i=0; i<arb->numContacts; i++){
			[renderer drawDot:arb->contacts[i].p radius:3.0 color:(Color){1,0,0,1}];
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
