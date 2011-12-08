@class PolyRenderer;

@interface ShowcaseDemo : NSObject

-(void)update:(NSTimeInterval)dt;

-(void)prepareStaticRenderer:(PolyRenderer *)renderer;
-(void)render:(PolyRenderer *)renderer;

@end
