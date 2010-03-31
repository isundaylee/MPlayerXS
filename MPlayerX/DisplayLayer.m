/*
 * MPlayerX - DisplayLayer.m
 *
 * Copyright (C) 2009 Zongyao QU
 * 
 * MPlayerX is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * MPlayerX is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with MPlayerX; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "DisplayLayer.h"
#import "fast_memcpy.h"

#define SAFEFREE(x)						{if(x){free(x); x = NULL;}}
#define SAFERELEASETEXTURECACHE(x)		{if(x){CVOpenGLTextureCacheRelease(x); x=NULL;}}
#define SAFERELEASEOPENGLBUFFER(x)		{if(x){CVOpenGLBufferRelease(x); x=NULL;}}

@implementation DisplayLayer

@synthesize fillScreen;

//////////////////////////////////////Init/Dealloc/////////////////////////////////////
- (id) init
{
	if (self = [super init]) {
		bufRaw = NULL;
		bufRef = NULL;
		cache = NULL;

		memset(&fmt, 0, sizeof(fmt));
		fmt.aspect = kDisplayAscpectRatioInvalid;

		fillScreen = NO;
		externalAspectRatio = kDisplayAscpectRatioInvalid;

		[self setDelegate:self];
		[self setMasksToBounds:YES];
		[self setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
	}
	return self;
}

-(id<CAAction>) actionForLayer:(CALayer*)layer forKey:(NSString*)event
{
	return ((id<CAAction>)[NSNull null]);
}

- (void)dealloc
{
	SAFERELEASETEXTURECACHE(cache);
	
	SAFERELEASEOPENGLBUFFER(bufRef);
	SAFEFREE(bufRaw);
	
	[super dealloc];
}

-(CIImage*) snapshot
{
	if (bufRef) {
		return [CIImage imageWithCVImageBuffer:bufRef];
	}
	return nil;
}

-(NSSize) displaySize
{
	return NSMakeSize(fmt.width, fmt.height);
}

-(CGFloat) aspectRatio
{
	if (externalAspectRatio > 0) {
		return externalAspectRatio;
	} else if (fmt.aspect > 0) {
		return fmt.aspect;
	}
	return kDisplayAscpectRatioInvalid;
}

-(void) setExternalAspectRatio:(CGFloat)ar
{
	externalAspectRatio = (ar>0)?(ar):(kDisplayAscpectRatioInvalid);
}

-(int) startWithWidth:(int) width height:(int) height pixelFormat:(OSType) pixelFormat aspect:(int)aspect
{
	@synchronized(self) {
		SAFERELEASEOPENGLBUFFER(bufRef);
		SAFEFREE(bufRaw);
		
		unsigned int pixelSize = ((pixelFormat == kYUVSPixelFormat)?2:4);
		
		fmt.width = width;
		fmt.height = height;
		fmt.imageSize = pixelSize * width * height;
		fmt.pixelFormat = pixelFormat;
		fmt.aspect = ((CGFloat)aspect)/100.0;
		
		bufRaw = malloc(fmt.imageSize);

		if (bufRaw) {
			CVReturn error = 
				CVPixelBufferCreateWithBytes(NULL, fmt.width, fmt.height, fmt.pixelFormat, 
											 bufRaw, fmt.width * pixelSize, 
											 NULL, NULL, NULL, &bufRef);
			if (error != kCVReturnSuccess) {
				bufRef = NULL;
				NSLog(@"buffer failed");
			}
		}
	}
	return (bufRef)?1:0;
}

-(void) draw:(void*)imageData
{
	if (bufRef) {
		fast_memcpy(bufRaw, imageData, fmt.imageSize);
		[self setNeedsDisplay];
	}
}

-(void) stop
{
	@synchronized(self) {
		SAFERELEASEOPENGLBUFFER(bufRef);		
		SAFEFREE(bufRaw);

		memset(&fmt, 0, sizeof(fmt));
		fmt.aspect = kDisplayAscpectRatioInvalid;

		[self setNeedsDisplay];		
	}
}

//////////////////////////////////////OpenGLLayer inherent/////////////////////////////////////
-(BOOL) asynchronous
{
	return NO;
}

-(CGLPixelFormatObj) copyCGLPixelFormatForDisplayMask:(uint32_t)mask
{
	CGLPixelFormatObj pf;
	GLint num = 1;
	
	CGLPixelFormatAttribute attr[] = {
		kCGLPFAAccelerated,
		kCGLPFADisplayMask,mask,
		0
	};
	
	CGLChoosePixelFormat(attr, &pf, &num);
	NSLog(@"pfrc:%d",CGLGetPixelFormatRetainCount(pf));
	return pf;
}

-(void) releaseCGLPixelFormat:(CGLPixelFormatObj)pf
{
	CGLReleasePixelFormat(pf);
}

-(CGLContextObj) copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf
{
	GLint i = 1;

	CGLContextObj ctx = [super copyCGLContextForPixelFormat:pf];

	CGLLockContext(ctx);

	CGLSetParameter(ctx, kCGLCPSwapInterval, &i);
	/*
	glEnable(GL_TEXTURE_RECTANGLE_ARB);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
	
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
	*/
	CGLEnable(ctx, kCGLCEMPEngine);
	
	SAFERELEASETEXTURECACHE(cache);
	CVReturn error = CVOpenGLTextureCacheCreate(NULL, NULL, ctx, pf, NULL, &cache);
	
	CGLUnlockContext(ctx);
	
	if(error != kCVReturnSuccess) {
		cache = NULL;
		NSLog(@"create cache failed");
	}
	return ctx;
}

- (void)releaseCGLContext:(CGLContextObj)ctx
{
	SAFERELEASETEXTURECACHE(cache);

	[super releaseCGLContext:ctx];
}

- (void)drawInCGLContext:(CGLContextObj)glContext 
			 pixelFormat:(CGLPixelFormatObj)pixelFormat
			forLayerTime:(CFTimeInterval)timeInterval 
			 displayTime:(const CVTimeStamp *)timeStamp
{
	CGLLockContext(glContext);	
	
	CGLSetCurrentContext(glContext);
	
	if (bufRef) {
	
		CVOpenGLTextureRef tex;
		
		CVReturn error = CVOpenGLTextureCacheCreateTextureFromImage(NULL, cache, bufRef, NULL, &tex);
		
		if (error == kCVReturnSuccess) {
			// draw
			CGRect rc = self.superlayer.bounds;
			CGFloat sAspect = [self aspectRatio];
			
			if (((sAspect * rc.size.height) > rc.size.width) == fillScreen) {
				rc.size.width = rc.size.height * sAspect;
			} else {
				rc.size.height = rc.size.width / sAspect;
			}
			
			[self setBounds:rc];
			
			GLenum target = CVOpenGLTextureGetTarget(tex);

			glEnable(target);
			glBindTexture(target, CVOpenGLTextureGetName(tex));
			
			glBegin(GL_QUADS);
			
			// 直接计算layer需要的尺寸
			glTexCoord2f(		 0,			 0);	glVertex2f(-1,	 1);
			glTexCoord2f(		 0, fmt.height);	glVertex2f(-1,	-1);
			glTexCoord2f(fmt.width, fmt.height);	glVertex2f( 1,	-1);
			glTexCoord2f(fmt.width,			 0);	glVertex2f( 1,	 1);
			
			glEnd();
			
			glDisable(target);
			CVOpenGLTextureRelease(tex);
			goto FLUSH;
		}
	}
	
	glClearColor(0, 0, 0, 0);
	glClear(GL_COLOR_BUFFER_BIT);
	
FLUSH:
	glFlush();
	CGLUnlockContext(glContext);
}
@end
