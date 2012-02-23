//
//  InstructionsController.m
//  ChipmunkShowcase
//
//  Created by Scott Lembcke on 2/22/12.
//  Copyright (c) 2012 Howling Moon Software. All rights reserved.
//

#import "AppDelegate.h"
#import "InstructionsController.h"

@implementation InstructionsController {
	IBOutlet UIImageView *_imageView;
}

-(IBAction)learnMore:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://chipmunk-physics.net/"]];
}

-(IBAction)getCode:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/slembcke/Chipmunk-Physics"]];
}

-(IBAction)play:(id)sender
{
	[(AppDelegate *)[UIApplication sharedApplication].delegate play];
}

-(void)viewDidLoad
{
	_imageView.image = [UIImage imageNamed:@"instructions.png"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end
