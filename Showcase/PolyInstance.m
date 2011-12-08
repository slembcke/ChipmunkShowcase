#import "PolyInstance.h"

#import "ObjectiveChipmunk.h"

@interface PolyInstance() {
	NSUInteger _vertexCount;
	Vertex *_vertexes;
}

@end


@implementation PolyInstance

@synthesize vertexCount = _vertexCount, vertexes = _vertexes;

-(id)initWithPolyShape:(ChipmunkPolyShape *)poly width:(cpFloat)width FillColor:(Color)fill lineColor:(Color)line;
{
	if((self = [super init])){
		NSUInteger vert_count = poly.count;
		
		struct ExtrudeVerts {cpVect offset, n;};
		struct ExtrudeVerts extrude[vert_count];
		bzero(extrude, sizeof(struct ExtrudeVerts)*vert_count);
		
		for(int i=0; i<vert_count; i++){
			cpVect v0 = [poly getVertex:(i-1+vert_count)%vert_count];
			cpVect v1 = [poly getVertex:i];
			cpVect v2 = [poly getVertex:(i+1)%vert_count];
			
			cpVect n1 = cpvnormalize(cpvperp(cpvsub(v1, v0)));
			cpVect n2 = cpvnormalize(cpvperp(cpvsub(v2, v1)));
			
			cpVect offset = cpvmult(cpvadd(n1, n2), 1.0/(cpvdot(n1, n2) + 1.0));
			extrude[i] = (struct ExtrudeVerts){offset, n2};
		}
		
		NSUInteger triangleCount = (fill.a > 0.0 ? vert_count - 2 : 0) + (line.a > 0.0 ? 6 : 2)*vert_count;
		
		Triangle *triangles = calloc(triangleCount, sizeof(Triangle));
		Triangle *cursor = triangles;
		
		if(fill.a > 0.0){
			for(int i=0; i<vert_count-2; i++){
				cpFloat inset = (line.a == 0.0 ? width : 0.0);
				cpVect v0 = cpvsub([poly getVertex:0  ], cpvmult(extrude[0  ].offset, inset));
				cpVect v1 = cpvsub([poly getVertex:i+1], cpvmult(extrude[i+1].offset, inset));
				cpVect v2 = cpvsub([poly getVertex:i+2], cpvmult(extrude[i+2].offset, inset));
				
				*cursor++ = (Triangle){{v0, cpvzero, fill}, {v1, cpvzero, fill}, {v2, cpvzero, fill},};
			}
		}
		
		for(int i=0; i<vert_count; i++){
			int j = (i+1)%vert_count;
			cpVect v0 = [poly getVertex:i];
			cpVect v1 = [poly getVertex:j];
			
			cpVect offset0 = extrude[i].offset;
			cpVect offset1 = extrude[j].offset;
			cpVect inner0 = cpvsub(v0, cpvmult(offset0, width));
			cpVect inner1 = cpvsub(v1, cpvmult(offset1, width));
			cpVect outer1 = cpvadd(v1, cpvmult(offset1, width));
			
			cpVect n0 = extrude[i].n;
			cpVect n1 = extrude[j].n;
			cpVect e1 = cpvadd(v0, cpvmult(n0, width));
			cpVect e2 = cpvadd(v1, cpvmult(n0, width));
			cpVect e3 = cpvadd(v1, cpvmult(n1, width));
			
			if(line.a > 0.0){
				*cursor++ = (Triangle){{inner0, cpvneg(n0), line}, {inner1, cpvneg(n0), line}, {v1, cpvzero, line}};
				*cursor++ = (Triangle){{inner0, cpvneg(n0), line}, {v0, cpvzero, line}, {v1, cpvzero, line}};
				*cursor++ = (Triangle){{e2, n0, line}, {v0, cpvzero, line}, {v1, cpvzero, line}};
				*cursor++ = (Triangle){{e2, n0, line}, {v0, cpvzero, line}, {e1, n0, line}};
				*cursor++ = (Triangle){{v1, cpvzero, line}, {e2, n0, line}, {outer1, offset1, line}};
				*cursor++ = (Triangle){{v1, cpvzero, line}, {e3, n1, line}, {outer1, offset1, line}};
			} else {
				*cursor++ = (Triangle){{inner0, cpvzero, fill}, {inner1, cpvzero, fill}, {v1, n0, fill}};
				*cursor++ = (Triangle){{inner0, cpvzero, fill}, {v0, n0, fill}, {v1, n0, fill}};
			}
		}
		
		_vertexCount = triangleCount*3;
		_vertexes = (Vertex *)triangles;
	}
	
	return self;
}

-(id)initWithSegmentShape:(ChipmunkSegmentShape *)seg width:(cpFloat)width FillColor:(Color)fill lineColor:(Color)line;
{
	if((self = [super init])){
		NSUInteger triangleCount = 6;
		
		cpVect a = seg.a;
		cpVect b = seg.b;
		
		cpVect n = cpvnormalize(cpvperp(cpvsub(b, a)));
		cpVect t = cpvperp(n);
		
		cpFloat radius = cpfmax(width, seg.radius);
		cpVect nw = cpvmult(n, radius);
		cpVect tw = cpvmult(t, radius);
		cpVect v0 = cpvsub(b, cpvadd(nw, tw));
		cpVect v1 = cpvadd(b, cpvsub(nw, tw));
		cpVect v2 = cpvsub(b, nw);
		cpVect v3 = cpvadd(b, nw);
		cpVect v4 = cpvsub(a, nw);
		cpVect v5 = cpvadd(a, nw);
		cpVect v6 = cpvsub(a, cpvsub(nw, tw));
		cpVect v7 = cpvadd(a, cpvadd(nw, tw));
		
		Triangle *triangles = calloc(triangleCount, sizeof(Triangle));
		triangles[0] = (Triangle){{v0, cpvneg(cpvadd(n, t)), line}, {v1, cpvsub(n, t), line}, {v2, cpvneg(n), line},};
		triangles[1] = (Triangle){{v3, n, line}, {v1, cpvsub(n, t), line}, {v2, cpvneg(n), line},};
		triangles[2] = (Triangle){{v3, n, line}, {v4, cpvneg(n), line}, {v2, cpvneg(n), line},};
		triangles[3] = (Triangle){{v3, n, line}, {v4, cpvneg(n), line}, {v5, n, line},};
		triangles[4] = (Triangle){{v6, cpvsub(t, n), line}, {v4, cpvneg(n), line}, {v5, n, line},};
		triangles[5] = (Triangle){{v6, cpvsub(t, n), line}, {v7, cpvadd(n, t), line}, {v5, n, line},};
		
		_vertexCount = triangleCount*3;
		_vertexes = (Vertex *)triangles;
	}
	
	return self;
}

-(id)initWithShape:(ChipmunkShape *)shape width:(cpFloat)width FillColor:(Color)fill lineColor:(Color)line;
{
	cpAssertSoft(fill.a > 0.0 || line.a > 0.0, "Creating a poly with a clear fill and line color.");
	
	if([shape isKindOfClass:[ChipmunkPolyShape class]]){
		return [self initWithPolyShape:(id)shape width:width FillColor:fill lineColor:line];
	}	else if([shape isKindOfClass:[ChipmunkSegmentShape class]]){
		return [self initWithSegmentShape:(id)shape width:width FillColor:fill lineColor:line];
	} else {
		NSLog(@"Could not make Poly for this object.");
		return nil;
	}
}

@end
