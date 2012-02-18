//
//  GLViewController.h
//  ChipmunkShowcase
//
//  Created by Scott Lembcke on 2/18/12.
//  Copyright (c) 2012 Howling Moon Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GLView.h"

@protocol GLViewControllerDelegate;

// GLKit is very multithreading unfriendly.
// Running any significant rendering on the main the main thread causes terrible input lag.
// Reimplementing GLKit as I go.
@interface GLViewController : UIViewController <GLViewDelegate>

@property (nonatomic, assign) IBOutlet id <GLViewControllerDelegate> delegate;

@property (nonatomic, readonly) NSInteger preferredFramesPerSecond;
//@property (nonatomic, readonly) NSInteger framesPerSecond;

//@property (nonatomic, getter=isPaused) BOOL paused;

//@property (nonatomic, readonly) NSInteger framesDisplayed;
//@property (nonatomic, readonly) NSTimeInterval timeSinceFirstResume;
//@property (nonatomic, readonly) NSTimeInterval timeSinceLastResume;
//@property (nonatomic, readonly) NSTimeInterval timeSinceLastUpdate;
//@property (nonatomic, readonly) NSTimeInterval timeSinceLastDraw;

//@property (nonatomic) BOOL pauseOnWillResignActive;
//@property (nonatomic) BOOL resumeOnDidBecomeActive;

@end


@protocol GLViewControllerDelegate <NSObject>

@required
- (void)glViewControllerUpdate:(GLViewController *)controller;

@optional
- (void)glViewController:(GLViewController *)controller willPause:(BOOL)pause;

@end
