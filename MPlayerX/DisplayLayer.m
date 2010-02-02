/*
 * MPlayerX - DisplayLayer.m
 *
 * Copyright (C) 2009 Zongyao QU
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "DisplayLayer.h"
#import "fast_memcpy.h"

#define SAFEFREE(x)						{if(x){free(x); x = NULL;}}
#define SAFERELEASETEXTURECACHE(x)		{if(x){CVOpenGLTextureCacheRelease(x); x=NULL;}}
#define SAFERELEASEOPENGLBUFFER(x)		{if(x){CVOpenGLBufferRelease(x); x=NULL;}}

@interface DisplayLayer (DisplayLayerInternal)
-(void) freeLocalBuffer;
-(BOOL) buildOpenGLEnvironment;
@end

@implementation DisplayLayer

@synthesize fillScreen;

//////////////////////////////////////Init/Dealloc/////////////////////////////////////
- (id) init
{
	if (self = [super init]) {
		bufRaw = NULL;
		bufRef = NULL;
		cache = NULL;
		_context = NULL;
		
		fmt.width = 0;
		fmt.height = 0;
		fmt.imageSize = 0;
		fmt.pixelFormat = 0;
		fmt.aspect = kDisplayAscpectRatioInvalid;
		
		fillScreen = NO;
		externalAspectRatio = kDisplayAscpectRatioInvalid;
		
		[self setMasksToBounds:YES];
		[self setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];

		CALayer *maskLayer = [CALayer layer];
		
		[maskLayer setDelegate:self];
		CGColorRef col = CGColorCreateGenericGray(0.0, 1.0);
		[maskLayer setBackgroundColor:col];
		CGColorRelease(col);
		[maskLayer setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];

		[self setMask:maskLayer];
	}
	return self;
}

- (void)dealloc
{
	[self freeLocalBuffer];
	
	[super dealloc];
}

-(void) setupWithSuperLayer:(CALayer*)root
{
	[self setBounds:[root bounds]];
	[self setPosition:CGPointMake(root.bounds.size.width/2, root.bounds.size.height/2)];
	
	CALayer *maskLayer = [self mask];

	[maskLayer setBounds:[root bounds]];
	[maskLayer setPosition:CGPointMake(root.bounds.size.width/2, root.bounds.size.height/2)];	
}

-(id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
	return ((id<CAAction>)[NSNull null]);
}

-(void) freeLocalBuffer
{
	SAFERELEASETEXTURECACHE(cache);
	SAFERELEASEOPENGLBUFFER(bufRef);
	
	SAFEFREE(bufRaw);

	memset(&fmt, 0, sizeof(fmt));
	fmt.aspect = kDisplayAscpectRatioInvalid;
	// TODO 这里需不需要重置需要考虑
	externalAspectRatio = kDisplayAscpectRatioInvalid;
}

-(BOOL) buildOpenGLEnvironment
{
	if (bufRaw && _context) {
		SAFERELEASETEXTURECACHE(cache);
		SAFERELEASEOPENGLBUFFER(bufRef);
		
		CVReturn error;
		CVOpenGLTextureRef texture;
				
		error = CVPixelBufferCreateWithBytes(NULL, fmt.width, fmt.height, fmt.pixelFormat, 
											 bufRaw, fmt.width * ((fmt.pixelFormat == kYUVSPixelFormat)?2:4), 
											 NULL, NULL, NULL, &bufRef);
		if (error != kCVReturnSuccess) {
			NSLog(@"buffer failed");
			return NO;
		}
		
		error = CVOpenGLTextureCacheCreate(NULL, 0, _context, CGLGetPixelFormat(_context), NULL, &cache);
		if(error != kCVReturnSuccess) {
			NSLog(@"textcache failed");
			SAFERELEASEOPENGLBUFFER(bufRef);
			return NO;
		}
		
		error = CVOpenGLTextureCacheCreateTextureFromImage(NULL, cache, bufRef,  0, &texture);
		if (error != kCVReturnSuccess) {
			NSLog(@"texture failed");
			SAFERELEASETEXTURECACHE(cache);
			SAFERELEASEOPENGLBUFFER(bufRef);
			return NO;
		}
		CVOpenGLTextureRelease(texture);
		return YES;
	}
	return NO;
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
	[self freeLocalBuffer];
	
	unsigned int pixelSize = ((pixelFormat == kYUVSPixelFormat)?2:4);
	
	fmt.width = width;
	fmt.height = height;
	fmt.imageSize = pixelSize * width * height;
	fmt.pixelFormat = pixelFormat;
	fmt.aspect = ((CGFloat)aspect)/100.0f;

	bufRaw = malloc(fmt.imageSize);
	
	[self buildOpenGLEnvironment];
	return (bufRaw)? 1:0;
}

-(void) draw:(void*)imageData
{
	if (bufRaw) {
		fast_memcpy(bufRaw, imageData, fmt.imageSize);
		[self setNeedsDisplay];		
	}
}

-(void) stop
{
	[self freeLocalBuffer];
	[self setNeedsDisplay];
}

//////////////////////////////////////OpenGLLayer inherent/////////////////////////////////////
-(BOOL) asynchronous
{
	return YES;
}

- (BOOL)canDrawInCGLContext:(CGLContextObj)ctx
				pixelFormat:(CGLPixelFormatObj)pf 
			   forLayerTime:(CFTimeInterval)t
				displayTime:(const CVTimeStamp *)ts
{
	return YES;
}

- (CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf
{	
	GLint i = 1;

	// 从父类得到context
	_context = [super copyCGLContextForPixelFormat:pf];

	// 设定context的更新速度，默认为0，设定为1
	CGLSetParameter(_context, kCGLCPSwapInterval, &i);

	glEnable(GL_TEXTURE_RECTANGLE_ARB);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
	
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);

	// 打开多线程支持
	CGLEnable(_context, kCGLCEMPEngine);
/*
	glDisable( GL_BLEND );
    glDisable( GL_DEPTH_TEST );
    glDepthMask( GL_FALSE );
    glDisable( GL_CULL_FACE) ;
*/	
	[self buildOpenGLEnvironment];

	return _context;
}

- (void)releaseCGLContext:(CGLContextObj)ctx
{
	SAFERELEASETEXTURECACHE(cache);
	SAFERELEASEOPENGLBUFFER(bufRef);
	_context = NULL;

	[super releaseCGLContext:ctx];
}

- (void)drawInCGLContext:(CGLContextObj)glContext 
			 pixelFormat:(CGLPixelFormatObj)pixelFormat
			forLayerTime:(CFTimeInterval)timeInterval 
			 displayTime:(const CVTimeStamp *)timeStamp
{
	CVOpenGLTextureRef tex;
	CVReturn error;
	
	CGLLockContext(glContext);	
	
	CGLSetCurrentContext(glContext);

	// 清理屏幕
	glClearColor(0, 0, 0, 1);
	glClear(GL_COLOR_BUFFER_BIT);
	
	if (bufRaw != NULL) {
		// 有图就画图
		error = CVOpenGLTextureCacheCreateTextureFromImage (NULL, cache, bufRef,  0, &tex);
		
		if (error == kCVReturnSuccess) {
			// 成功创建纹理
			CGFloat x, y;
			CGSize sz = [self bounds].size;
			CGFloat dAspect = (sz.width)/(sz.height);
			CGFloat sAspect = [self aspectRatio];
			
			glEnable(CVOpenGLTextureGetTarget(tex));
			glBindTexture(CVOpenGLTextureGetTarget(tex), CVOpenGLTextureGetName(tex));
			
			glBegin(GL_QUADS);

			if (sAspect > dAspect) {
				if (fillScreen) {
					x = sAspect/dAspect;
					y = 1;
				}
				else {
					x = 1;
					y = dAspect/sAspect;
				}
			}
			else {
				if (fillScreen) {
					x = 1;
					y = dAspect/sAspect;
				}
				else {
					x = sAspect/dAspect;
					y = 1;
				}
			}

			// mask的大小适中和 播放内容的大小一致
			[[self mask] setBounds:CGRectMake(0.0, 0.0, sz.width*x+0.5, sz.height*y+0.5)];
			
			glTexCoord2f(		 0,			 0);	glVertex2f(-x,	 y);
			glTexCoord2f(		 0, fmt.height);	glVertex2f(-x,	-y);
			glTexCoord2f(fmt.width, fmt.height);	glVertex2f( x,	-y);
			glTexCoord2f(fmt.width,			 0);	glVertex2f( x,	 y);
			
			glEnd();
			
			glDisable(CVOpenGLTextureGetTarget(tex));
			CVOpenGLTextureRelease(tex);
		}
	}
	glFlush();
	CGLUnlockContext(glContext);
}
@end
