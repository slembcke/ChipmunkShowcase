//
//  GLViewController.m
//  ChipmunkShowcase
//
//  Created by Scott Lembcke on 2/18/12.
//  Copyright (c) 2012 Howling Moon Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "GLViewController.h"

@implementation GLViewController {
	CADisplayLink *_displayLink;
}

@synthesize delegate = _delegate;

-(NSInteger)preferredFramesPerSecond
{
	return 60.0;
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

- (void)viewWillAppear:(BOOL)animated
{
	[super viewDidLoad];
	
	_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update:)];
	_displayLink.frameInterval = 5;
	[_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)viewDidDisappear:(BOOL)animated
{
	[_displayLink invalidate];
	_displayLink = nil;
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	NSLog(@"rotating");
}

-(void)update:(CADisplayLink *)sender;
{
//	[_delegate glViewControllerUpdate:self];
//	[(GLView *)self.view display];
}

-(void)glView:(GLView *)view drawInRect:(CGRect)rect
{
	
}

@end
