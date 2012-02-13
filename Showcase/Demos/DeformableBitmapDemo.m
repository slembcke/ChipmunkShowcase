#import "ShowcaseDemo.h"

#import "ChipmunkAutoGeometry.h"

@interface DeformableBitmapDemo : ShowcaseDemo @end
@implementation DeformableBitmapDemo {
	ChipmunkBasicTileCache *_tiles;
	ChipmunkCGContextSampler *_sampler;
}

-(NSString *)name
{
	return @"Deformable Bitmap";
}

#define PIXEL_SIZE 4
#define TILE_SIZE 128

-(void)setup
{
	int width = 640;
	int height = 480;
	
	// Subsample the data from a small context for efficiency.
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	_sampler = [[ChipmunkCGContextSampler alloc] initWithWidth:width/PIXEL_SIZE height:height/PIXEL_SIZE colorSpace:colorSpace bitmapInfo:kCGImageAlphaNone component:0];
	CGColorSpaceRelease(colorSpace);
	
	[_sampler setBorderValue:1.0];
	
	// The output rectangle should be inset slightly so that we sample pixel centers, not edges.
	// This along with the tileOffset below will make sure the pixels line up with the geometry perfectly.
	CGFloat hw = width/2.0 - 0.5*PIXEL_SIZE;
	CGFloat hh = height/2.0 - 0.5*PIXEL_SIZE;
	_sampler.outputRect = cpBBNew(-hw, -hh, hw, hh);
	
	// Samples are spread out over the entire tile size starting at the edges.
	// You must sample 1 point more than you'd think to line up with the pixels.
	_tiles = [[ChipmunkBasicTileCache alloc] initWithSampler:_sampler space:self.space tileSize:TILE_SIZE samplesPerTile:TILE_SIZE/PIXEL_SIZE + 1 cacheSize:256];
	_tiles.tileOffset = cpv(-0.5*PIXEL_SIZE, -0.5*PIXEL_SIZE); // See above
	_tiles.segmentRadius = 1;
	_tiles.simplifyThreshold = 2;
	_tiles.segmentLayers = NOT_GRABABLE_MASK;
	
	// Set the CGContext's transform to match it's Chipmunk coords.
	CGContextConcatCTM(_sampler.context, CGAffineTransformMake(1.0/PIXEL_SIZE, 0.0, 0.0, 1.0/PIXEL_SIZE, width/2.0/PIXEL_SIZE, height/2.0/PIXEL_SIZE));
	
	// Clear it to white.
	CGContextSetGrayFillColor(_sampler.context, 1.0, 1.0);
	CGContextFillRect(_sampler.context, CGRectMake(-320.0, -240.0, width, height));
	
	// Draw a hole in the middle of the screen.
	CGContextSetGrayFillColor(_sampler.context, 0.0, 1.0);
	CGContextFillRect(_sampler.context, CGRectMake(-160.0, -20.0, 320.0, 240.0));
	
	for(int i=0; i<150; i++){
		cpFloat radius = 10.0f;
		cpFloat mass = 1.0;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
		body.pos = cpvadd(cpv(-150, -10), cpv(300.0*frand(), 220.0*frand()));

		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
		shape.elasticity = 0.0f;
		shape.friction = 0.9f;
	}
}

static cpBB
CGRect2cpBB(CGRect r)
{
	cpFloat l = r.origin.x;
	cpFloat b = r.origin.y;
	return cpBBNew(l, b, l + r.size.width, b + r.size.height);
}

-(void)drawEllipseAt:(cpVect)pos
{
	cpFloat radius = 30.0;
	CGRect rect = CGRectMake(pos.x - radius, pos.y - radius, radius*2.0, radius*2.0);
	
	CGContextFillEllipseInRect(_sampler.context, rect);
	
	[_tiles markDirtyRect:CGRect2cpBB(rect)];
}

-(void)tick:(cpFloat)dt;
{
	[_tiles ensureRect:cpBBNew(-320, -240, 320, 240)];
	
	self.space.gravity = cpvmult([Accelerometer getAcceleration], 300.0);
	[super tick:dt];
}

//MARK: Override touch handlers

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for(UITouch *touch in touches){
		cpVect pos = [self convertTouch:touch];
		
		CGContextSetGrayFillColor(_sampler.context, 0.0, 1.0);
		[self drawEllipseAt:pos];
	}
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for(UITouch *touch in touches){		
		CGContextSetGrayFillColor(_sampler.context, 0.0, 1.0);
		[self drawEllipseAt:[self convertTouch:touch]];
	}
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
}

@end
