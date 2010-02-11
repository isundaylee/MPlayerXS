/*
 * MPlayerX - DisplayLayer.h
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <OpenGL/gl.h> 

// 这个值必须小于0，内部实际上会用0做比较
#define kDisplayAscpectRatioInvalid		(-1)

typedef struct {
	size_t width;
	size_t height;
	size_t imageSize;
	OSType pixelFormat;
	CGFloat aspect;
}DisplayFormat;

@interface DisplayLayer : CAOpenGLLayer
{
	void *bufRaw;
	CVOpenGLBufferRef bufRef;
	CVOpenGLTextureCacheRef cache;

	CGLContextObj _context;
	DisplayFormat fmt;
	BOOL fillScreen;
	CGFloat externalAspectRatio;
}

@property (readwrite, assign) BOOL fillScreen;

-(NSSize) displaySize;
-(CGFloat) aspectRatio;
-(void) setExternalAspectRatio:(CGFloat)ar;

-(int) startWithWidth:(int)width height:(int)height pixelFormat:(OSType)pixelFormat aspect:(int)aspect;
-(void) draw:(void*)imageData;
-(void) stop;

-(CIImage*) snapshot;

@end
