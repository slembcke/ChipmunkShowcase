#import "ObjectiveChipmunk.h"

/// Simple class to implement multitouch grabbing of physics objects.
@interface ChipmunkMultiGrab : NSObject {
	ChipmunkSpace *_space;
	NSMutableArray *_grabs;
	
	cpFloat _smoothing;
	cpFloat _force;
	cpFloat _grabFriction;
	cpFloat _grabRotaryFriction;
	cpFloat _grabRadius;
	
	cpLayers _layers;
	cpGroup _group;
}

/// Layers used for the point query when grabbing objects.
@property(nonatomic, assign) cpLayers layers;

/// Group used for the point query when grabbing objects
@property(nonatomic, assign) cpGroup group;

/// Amount of friction applied by the touch.
/// Should be less than the grabForce. Defaults to 0.0.
@property(nonatomic, assign) cpFloat grabFriction;

/// The amount torque to apply to the grab to keep it from spinning.
/// Defaults to 0.0.
@property(nonatomic, assign) cpFloat grabRotaryFriction;

/// On a touch screen, a single point query can make it really hard to grab small objects with a fat finger.
/// By providing a radius, it will make it much easier for users to grab objects.
/// Defaults to 0.0.
@property(nonatomic, assign) cpFloat grabRadius;

/**
	@c space is the space to grab shapes in.
	@c smoothing is the amount of mouse smoothing to apply as percentage of remaining error per second.
	cpfpow(0.8, 60) is a good starting point that provides fast response, but smooth mouse updates.
	@c force is the force the grab points can apply.
*/
-(id)initForSpace:(ChipmunkSpace *)space withSmoothing:(cpFloat)smoothing withGrabForce:(cpFloat)force;

/// Start tracking a new grab point
-(BOOL)beginLocation:(cpVect)pos;

/// Update a grab point.
-(void)updateLocation:(cpVect)pos;

/// End a grab point.
-(void)endLocation:(cpVect)pos;

@end
