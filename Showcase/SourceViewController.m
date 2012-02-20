//
//  SourceViewController.m
//  ChipmunkShowcase
//
//  Created by Scott Lembcke on 2/20/12.
//  Copyright (c) 2012 Howling Moon Software. All rights reserved.
//

#import "SourceViewController.h"
#import "ShowcaseDemo.h"

@implementation SourceViewController {
	NSString *_demoName;
	
	IBOutlet UINavigationItem *_title;
	IBOutlet UIWebView *_webView;
}

-(IBAction)dismiss
{
	[self dismissModalViewControllerAnimated:TRUE];
}

- (id)initWithDemoName:(NSString *)demoName;
{
	if((self = [super initWithNibName:@"SourceViewController" bundle:nil])){
		_demoName = demoName;
	}
	
	return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	ShowcaseDemo *obj = [NSClassFromString(_demoName) alloc];
	_title.title = obj.name;
	
	NSURL *source_url = [[NSBundle mainBundle] URLForResource:_demoName withExtension:@"m" subdirectory:@"Demos"];
	NSString *source = [NSString stringWithContentsOfURL:source_url usedEncoding:nil error:nil];
	
	NSURL *html_url = [[NSBundle mainBundle] URLForResource:@"SourceViewTemplate" withExtension:@"html"];
	NSString *template = [NSString stringWithContentsOfURL:html_url usedEncoding:nil error:nil];
	NSString *html = [NSString stringWithFormat:template, source];
	[_webView loadHTMLString:html baseURL:html_url];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end
