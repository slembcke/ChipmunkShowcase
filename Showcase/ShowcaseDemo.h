#import "PolyRenderer.h"

#define GRABABLE_MASK_BIT (1<<31)
#define NOT_GRABABLE_MASK (~GRABABLE_MASK_BIT)

@interface ShowcaseDemo : NSObject

@property(nonatomic, assign) Transform touchTransform;

-(void)update:(NSTimeInterval)dt;

-(void)prepareStaticRenderer:(PolyRenderer *)renderer;
-(void)render:(PolyRenderer *)renderer;

@end
