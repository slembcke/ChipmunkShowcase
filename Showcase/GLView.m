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

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "GLView.h"

@implementation GLView {
	GLuint _framebuffer;
	GLuint _renderbuffer;
	
	BOOL _isRendering;
	dispatch_queue_t _renderQueue;
}

@synthesize isRendering = _isRendering;

@synthesize context = _context;

@synthesize drawableWidth = _drawableWidth, drawableHeight = _drawableHeight;

-(void)sync
{
	dispatch_sync(_renderQueue, ^{});
}

-(void)runInRenderQueue:(void (^)(void))block sync:(BOOL)sync;
{
	(sync ? dispatch_sync : dispatch_async)(_renderQueue, ^{
		[EAGLContext setCurrentContext:_context];
		
		block();
		
		GLenum err = 0;
		for(err = glGetError(); err; err = glGetError()) NSLog(@"GLError: 0x%04X", err);
		NSAssert(err == GL_NO_ERROR, @"Aborting due to GL Errors.");
		
		[EAGLContext setCurrentContext:nil];
	});
}

//MARK: Framebuffer

- (BOOL)createFramebuffer
{
	glGenFramebuffers(1, &_framebuffer);
	glGenRenderbuffers(1, &_renderbuffer);
	
	glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
	
	[_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
	
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_drawableWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_drawableHeight);
	
	NSAssert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, @"Framebuffer creation failed 0x%x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
	NSLog(@"New framebuffer: %dx%d", _drawableWidth, _drawableHeight);
	
	glViewport(0, 0, _drawableWidth, _drawableHeight);
	
	return YES;
}

- (void)destroyFramebuffer
{
	glDeleteFramebuffers(1, &_framebuffer);
	_framebuffer = 0;
	
	glDeleteRenderbuffers(1, &_renderbuffer);
	_renderbuffer = 0;
}

-(void)clear
{
	const GLenum discards[]  = {GL_COLOR_ATTACHMENT0};
	glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
	
//	glClearColor(52.0/255.0, 62.0/255.0, 72.0/255.0, 1.0);
	glClearColor(0, 0, 0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);
}

- (void)layoutSubviews
{
	[self runInRenderQueue:^{
		[self destroyFramebuffer];
		[self createFramebuffer];
		[self clear];
	} sync:TRUE];
}

-(void)setContext:(EAGLContext *)context
{
	[self runInRenderQueue:^{
		_context = context;
		NSAssert(_context && [EAGLContext setCurrentContext:_context] && [self createFramebuffer], @"Failed to set up context.");
	} sync:TRUE];
}

//MARK: Memory methods

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder
{
	if((self = [super initWithCoder:coder])) {
		CAEAGLLayer *layer = (CAEAGLLayer*) self.layer;
		
		layer.opaque = YES;
		layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
			kEAGLColorFormatRGB565, kEAGLDrawablePropertyColorFormat,
			nil
		];
		
		layer.contentsScale = [UIScreen mainScreen].scale;
		
		_renderQueue = dispatch_queue_create("net.chipmunk-physics.showcase-renderqueue", NULL);
	}
	
	return self;
}

-(void)dealloc
{
	[self runInRenderQueue:^{
		[self destroyFramebuffer];
	} sync:TRUE];
	
	dispatch_release(_renderQueue);
}

//MARK: Render methods

-(void)display:(void (^)(void))block sync:(BOOL)sync;
{
	// Only queue one frame to render at a time unless synced.
	if(sync || !_isRendering){
		_isRendering = TRUE;
		
		[self runInRenderQueue:^{
			glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
			
			block();
			
			glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
			[_context presentRenderbuffer:GL_RENDERBUFFER];
						
			_isRendering = FALSE;
		} sync:sync];
	}
}

@end
