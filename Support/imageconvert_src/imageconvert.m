//  Created by Scott Lembcke on 5/3/2011.
//  Copyright 2010 Howling Moon Software. All rights reserved.

#import <Cocoa/Cocoa.h>

// Modified for the Atari Super Bunny Breakout Project to export retina and regular sized graphics.
int main(int argc, char *argv[])
{
	if(argc != 4){
		printf("usage: imageconvert <scale> <infile> <outfile>\n");
		abort();
	}
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init]; {
		NSString* in_path = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
		CFURLRef in_url = (CFURLRef)[NSURL fileURLWithPath:in_path];
		
		CGImageSourceRef image_source = CGImageSourceCreateWithURL(in_url, NULL);
		CGImageRef image = CGImageSourceCreateImageAtIndex(image_source, 0, NULL);
		
		NSString* out_path = [NSString stringWithCString:argv[3] encoding:NSUTF8StringEncoding];
		CFURLRef out_url = (CFURLRef)[NSURL fileURLWithPath:out_path];
		CFStringRef out_extension = (CFStringRef)[out_path pathExtension];
		CFStringRef out_type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, out_extension, NULL);
		
		CGImageRef out_image = image;
		
		double scale = 1.0;
		sscanf(argv[1], "%lf", &scale);
		if(scale != 1.0){
			size_t width = CGImageGetWidth(image)*scale;
			size_t height = CGImageGetHeight(image)*scale;
			size_t bpc = CGImageGetBitsPerComponent(image);
			size_t bpp = 32; // Hard wire this
			size_t stride = width*((bpp + 7)/8);
			CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
			CGBitmapInfo bitmap_info = CGImageGetBitmapInfo(image)&kCGBitmapAlphaInfoMask;
			
			if(bitmap_info == kCGImageAlphaNone) bitmap_info = kCGImageAlphaNoneSkipLast;
			
			void *buffer = calloc(height, stride);
			CGContextRef context = CGBitmapContextCreate(buffer, width, height, bpc, stride, colorspace, bitmap_info);
			
			CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
			CGContextDrawImage(context, CGRectMake(0.0, 0.0, width, height), image);
			
			CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, buffer, stride*height, NULL);
			out_image = CGImageCreate(width, height, bpc, bpp, stride, colorspace, bitmap_info, dataProvider, NULL, false, kCGRenderingIntentDefault);
		}
		
		CGImageDestinationRef image_destination = CGImageDestinationCreateWithURL(out_url, out_type, 1, NULL);
		CGImageDestinationAddImage(image_destination, out_image, NULL);
		CGImageDestinationFinalize(image_destination);
	}[pool release];
	
	return EXIT_SUCCESS;
}
