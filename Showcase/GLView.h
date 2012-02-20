//
//  GLView.h
//  ChipmunkShowcase
//
//  Created by Scott Lembcke on 2/18/12.
//  Copyright (c) 2012 Howling Moon Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


@class EAGLContext;
@protocol GLViewDelegate;

// GLKit is very multithreading unfriendly.
// Running any significant rendering on the main the main thread causes terrible input lag.
// Reimplementing GLKit as I go using EAGLView.m as a reference.
@interface GLView : UIView

-(void)runInRenderQueue:(void (^)(void))block;

@property(nonatomic, readonly) BOOL isRendering;

@property (nonatomic, assign) IBOutlet id <GLViewDelegate> delegate;

@property (nonatomic, retain) EAGLContext *context;

@property (nonatomic, readonly) NSInteger drawableWidth;
@property (nonatomic, readonly) NSInteger drawableHeight;

//@property (nonatomic) GLViewDrawableColorFormat drawableColorFormat;
//@property (nonatomic) GLViewDrawableDepthFormat drawableDepthFormat;
//@property (nonatomic) GLViewDrawableStencilFormat drawableStencilFormat;
//@property (nonatomic) GLViewDrawableMultisample drawableMultisample;

//- (void)bindDrawable;
//- (void)deleteDrawable;
//- (UIImage *)snapshot;

//@property (nonatomic) BOOL enableSetNeedsDisplay;

-(void)display:(void (^)(void))block;

@end


@protocol GLViewDelegate <NSObject>

@required
- (void)glView:(GLView *)view drawInRect:(CGRect)rect;

@end
