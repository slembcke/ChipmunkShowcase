/* Copyright (c) 2012 Scott Lembcke and Howling Moon Software
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

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
