#import "PolyInstance.h"

#import "ObjectiveChipmunk.h"

@interface PolyInstance() {
	NSUInteger _vertexCount;
	Vertex *_vertexes;
}

@end


@implementation PolyInstance

@synthesize vertexCount = _vertexCount, vertexes = _vertexes;

-(id)initWithShape:(ChipmunkShape *)shape FillColor:(Color)fill lineColor:(Color)line;
{
	if((self = [super init])){
		ChipmunkPolyShape *poly = (id)shape;
		NSUInteger vert_count = poly.count;
		
		// TODO could be simplified
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
		
		cpAssertSoft(fill.a > 0.0 || line.a > 0.0, "Creating a poly with a clear fill and line color.");
		NSUInteger triangleCount = (fill.a > 0.0 ? vert_count - 2 : 0) + (line.a > 0.0 ? 6 : 2)*vert_count;
		
		Triangle *triangles = calloc(triangleCount, sizeof(Triangle));
		Triangle *cursor = triangles;
		
		if(fill.a > 0.0){
			for(int i=0; i<vert_count-2; i++){
				cpFloat inset = (line.a == 0.0 ? WIDTH : 0.0);
				cpVect v0 = cpvsub([poly getVertex:0  ], cpvmult(extrude[0  ].offset, inset));
				cpVect v1 = cpvsub([poly getVertex:i+1], cpvmult(extrude[i+1].offset, inset));
				cpVect v2 = cpvsub([poly getVertex:i+2], cpvmult(extrude[i+2].offset, inset));
				
				*cursor++ = (Triangle){
					{v0, cpvzero, fill},
					{v1, cpvzero, fill},
					{v2, cpvzero, fill},
				};
			}
		}
		
		for(int i=0; i<vert_count; i++){
			int j = (i+1)%vert_count;
			cpVect v0 = [poly getVertex:i];
			cpVect v1 = [poly getVertex:j];
			
			cpVect offset0 = extrude[i].offset;
			cpVect offset1 = extrude[j].offset;
			cpVect inner0 = cpvsub(v0, cpvmult(offset0, WIDTH));
			cpVect inner1 = cpvsub(v1, cpvmult(offset1, WIDTH));
			cpVect outer1 = cpvadd(v1, cpvmult(offset1, WIDTH));
			
			cpVect n0 = extrude[i].n;
			cpVect n1 = extrude[j].n;
			cpVect e1 = cpvadd(v0, cpvmult(n0, WIDTH));
			cpVect e2 = cpvadd(v1, cpvmult(n0, WIDTH));
			cpVect e3 = cpvadd(v1, cpvmult(n1, WIDTH));
			
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

@end
