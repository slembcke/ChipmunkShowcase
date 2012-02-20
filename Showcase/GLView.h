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

@interface GLView : UIView

@property (nonatomic, retain) EAGLContext *context;

@property (nonatomic, readonly) NSInteger drawableWidth;
@property (nonatomic, readonly) NSInteger drawableHeight;

@property(nonatomic, readonly) BOOL isRendering;

-(void)sync;
-(void)runInRenderQueue:(void (^)(void))block sync:(BOOL)sync;
-(void)display:(void (^)(void))block sync:(BOOL)sync;

@end
