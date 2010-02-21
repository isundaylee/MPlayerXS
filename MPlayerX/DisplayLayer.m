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
	[self freeLocalBuffer];
	
	[super dealloc];
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
		//CVOpenGLTextureRef texture;
				
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
		
		/*
		error = CVOpenGLTextureCacheCreateTextureFromImage(NULL, cache, bufRef,  0, &texture);
		if (error != kCVReturnSuccess) {
			NSLog(@"texture failed");
			SAFERELEASETEXTURECACHE(cache);
			SAFERELEASEOPENGLBUFFER(bufRef);
			return NO;
		}
		CVOpenGLTextureRelease(texture);
		*/
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
	return NO;
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
	glClearColor(0, 0, 0, 0);
	glClear(GL_COLOR_BUFFER_BIT);
	
	if (bufRaw) {
		// 有图就画图
		error = CVOpenGLTextureCacheCreateTextureFromImage (NULL, cache, bufRef,  0, &tex);
		
		if (error == kCVReturnSuccess) {
			// 成功创建纹理
			CGRect rc = self.superlayer.bounds;
			CGFloat sAspect = [self aspectRatio];
			
			if (((sAspect * rc.size.height) > rc.size.width) == fillScreen) {
				rc.size.width = rc.size.height * sAspect;
			} else {
				rc.size.height = rc.size.width / sAspect;
			}
			
			[self setBounds:rc];
			
			glEnable(CVOpenGLTextureGetTarget(tex));
			glBindTexture(CVOpenGLTextureGetTarget(tex), CVOpenGLTextureGetName(tex));
			
			glBegin(GL_QUADS);
			
			// 直接计算layer需要的尺寸
			glTexCoord2f(		 0,			 0);	glVertex2f(-1,	 1);
			glTexCoord2f(		 0, fmt.height);	glVertex2f(-1,	-1);
			glTexCoord2f(fmt.width, fmt.height);	glVertex2f( 1,	-1);
			glTexCoord2f(fmt.width,			 0);	glVertex2f( 1,	 1);
			
			glEnd();
			
			glDisable(CVOpenGLTextureGetTarget(tex));
			CVOpenGLTextureRelease(tex);
		}
	}

	glFlush();
	CGLUnlockContext(glContext);
}
@end
