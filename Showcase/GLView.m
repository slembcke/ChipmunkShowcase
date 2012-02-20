//
//  GLView.m
//  ChipmunkShowcase
//
//  Created by Scott Lembcke on 2/18/12.
//  Copyright (c) 2012 Howling Moon Software. All rights reserved.
//

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

-(void)runInRenderQueue:(void (^)(void))block
{
	dispatch_async(_renderQueue, ^{
		[EAGLContext setCurrentContext:_context];
		
		block();
		
		GLenum err = 0;
		for(err = glGetError(); err; err = glGetError()) NSLog(@"GLError0x%04X", err);
		NSAssert(err == GL_NO_ERROR, @"GL Errors!");
		
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

- (void)layoutSubviews
{
	[self runInRenderQueue:^{
		[self destroyFramebuffer];
		[self createFramebuffer];
//		[self drawView];
	}];
}

-(void)setContext:(EAGLContext *)context
{
	[self runInRenderQueue:^{
		_context = context;
		NSAssert(_context && [EAGLContext setCurrentContext:_context] && [self createFramebuffer], @"Failed to set up context.");
	}];
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
			kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, // TODO 565 instead?
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
	}];
	
	dispatch_release(_renderQueue);
}

//MARK: Render methods

-(void)display:(void (^)(void))block;
{
	// Only queue one frame to render at a time.
	if(_isRendering) return;
	
	_isRendering = TRUE;
	[self runInRenderQueue:^{
		glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
		
		block();
		
		glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
		[_context presentRenderbuffer:GL_RENDERBUFFER];
		
		for(GLenum err = glGetError(); err; err = glGetError()) NSLog(@"GLError(%s:%d) 0x%04X", __FILE__, __LINE__, err);
		_isRendering = FALSE;
	}];
}

@end
