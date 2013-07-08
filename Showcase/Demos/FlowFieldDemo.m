/* Copyright (c) 2012 Scott Lembcke and Howling Moon Software
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "ShowcaseDemo.h"
#import "ChipmunkHastySpace.h"


// Make a custom body subclass with a custom velocity integration method.
@interface FlowBody : ChipmunkBody @end
@implementation FlowBody{
@protected
	int _color;
}

-(id)initWithMass:(cpFloat)mass andMoment:(cpFloat)moment
{
	if((self = [super initWithMass:mass andMoment:moment])){
		_color = (rand()>>16) % 7;
	}
	
	return self;
}

-(void)updateVelocity:(cpFloat)dt gravity:(cpVect)gravity damping:(cpFloat)damping
{
    cpVect p = self.pos;
    cpVect inwards = cpvmult(cpvneg(p), 0.8f);
    cpVect spin = cpvmult(cpvperp(p), 0.5f);
    cpFloat scale = 1.0/20.0;
    cpVect turb = cpvmult(cpv(cpfsin(p.x*scale), cpfsin(p.y*scale)), 100.0f);
    cpVect g = cpvadd(cpvadd(inwards, spin), turb);
	[super updateVelocity:dt gravity:g damping:damping];
}

-(void)render:(PolyRenderer *)renderer
{
	[renderer drawRing:self.pos radius:5.3 which:_color + 7];
}

@end

@interface RingBody : FlowBody @end
@implementation RingBody

-(void)render:(PolyRenderer *)renderer
{
	[renderer drawRing:self.pos radius:16.0 which:_color];
}

@end


// Now actually implement the demo. \o/
@interface FlowFieldDemo : ShowcaseDemo @end
@implementation FlowFieldDemo {
	float _explosionTime;
	cpVect _explosionLocation;
}

-(NSString *)name
{
	return @"Flow Field Projectiles";
}

static cpVect
rand_pos()
{
	cpVect v;
	do {
		v = cpvmult(frand_unit_circle(), 500);
	} while(cpvlength(v) < 100.0f);
	
	return v;
}

-(void)addBall:(cpVect)direction at:(cpVect)point
{
	const cpFloat radius = 1.0f;
	const cpFloat mass = 1.0f;
	
	ChipmunkBody *body = [self.space add:[FlowBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
	body.pos = point;
	body.vel = cpvmult(direction, 150);
	
	ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
	shape.elasticity = 0.0f;
	shape.friction = 0.7f;
	shape.layers = 1;
}

-(void)addRing:(cpVect)direction at:(cpVect)point
{
	const cpFloat radius = 1.0f;
	const cpFloat mass = 2.0f;
	
	ChipmunkBody *body = [self.space add:[RingBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
	body.pos = point;
	body.vel = cpvmult(direction, 150);
	
	ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
	shape.elasticity = 0.0f;
	shape.friction = 0.7f;
	shape.layers = 2;
	shape.group = @"foo";
}

-(void)setup
{
    self.space.damping = 0.5;
    
    for(int i=0; i<2000; i++){
        cpVect pos = cpvmult(frand_unit_circle(), 1000.0);
        [self addBall:cpvzero at:pos];
    }
		
    for(int i=0; i<600; i++){
        cpVect pos = cpvmult(frand_unit_circle(), 1000.0);
        [self addRing:cpvzero at:pos];
    }
		
		_explosionTime = 10.0;
		_explosionLocation = cpv(53, 53);
}

-(void)tick:(cpFloat)dt
{
	[super tick:dt];
	
	_explosionTime -= dt;
	if(_explosionTime < 0.0){
		cpBB bb = cpBBNewForCircle(_explosionLocation, 50.0);
		cpSpaceBBQuery_b(self.space.space, bb, CP_ALL_LAYERS, CP_NO_GROUP, ^(cpShape *shape){
			cpBody *body = cpShapeGetBody(shape);
			
			cpVect delta = cpvsub(cpBodyGetPos(body), _explosionLocation);
			cpFloat strength = cpflerp(500.0, 0.0, cpfclamp01(cpvlength(delta)/75.0));
			cpVect explosion = cpvmult(cpvnormalize(delta), strength/body->m);
			cpBodyApplyImpulse(body, explosion, cpvzero);
		});
		
		_explosionLocation = cpvrotate(_explosionLocation, cpv(0, 1));
		_explosionTime += 3.0;
	}
}

//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
//{
//    for(UITouch *touch in touches){
//        cpVect origin = cpv(-320, 0);
//        cpVect point = [self convertTouch:touch];
//				NSLog(@"Point (%5.2f, %5.2f).", point.x, point.y);
//				
//        cpVect direction = cpvnormalize(cpvsub(point, origin));
//        
//        for(int i=0; i<100; i++){
//            cpVect offset = cpvmult(frand_unit_circle(), 50.0);
//            [self addBall:cpvzero at:cpvadd(point, offset)];
//        }
//    }
//}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {}

struct RenderContext {
	__unsafe_unretained PolyRenderer *renderer;
	NSTimeInterval accumulator;
};

static void
RenderDot(cpBody *body, struct RenderContext *context)
{
//	[context->renderer drawDot:pos radius:2.0 color:SHAPE_OUTLINE_COLOR];
	
	FlowBody *b = body->data;
	[b render:context->renderer];
}

-(void)render:(PolyRenderer *)renderer showContacts:(BOOL)showContacts;
{
	cpSpaceEachBody(self.space.space, (cpSpaceBodyIteratorFunc)RenderDot, &(struct RenderContext){renderer, self.accumulator});
}

@end
