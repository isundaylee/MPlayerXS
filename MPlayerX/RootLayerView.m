/*
 * MPlayerX - RootLayerView.m
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

#import <Quartz/Quartz.h>
#import "def.h"
#import "RootLayerView.h"
#import "DisplayLayer.h"
#import "ControlUIView.h"
#import "PlayerController.h"
#import "ShortCutManager.h"

#define kOnTopModeNormal		(0)
#define kOnTopModeAlways		(1)
#define kOnTopModePlaying		(2)

#define kSnapshotSaveDefaultPath	(@"~/Desktop")

@interface RootLayerView (RootLayerViewInternal)
-(NSSize) calculateContentSize;
@end

@implementation RootLayerView

@synthesize fullScrnDevID;

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithInt:kOnTopModePlaying], kUDKeyOnTopMode,
					   kSnapshotSaveDefaultPath, kUDKeySnapshotSavePath,
					   [NSNumber numberWithBool:NO], kUDKeyStartByFullScreen,
					   nil]];
}

#pragma mark Init/Dealloc
- (id) initWithFrame:(NSRect)frameRect
{
	if (self = [super initWithFrame:frameRect]) {
		// 成功创建self
		trackingArea = [[NSTrackingArea alloc] initWithRect:NSInsetRect(frameRect, 1, 1) 
													options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingAssumeInside
													  owner:self
												   userInfo:nil];
		[self addTrackingArea:trackingArea];
		shouldResize = NO;
		dispLayer = [[DisplayLayer alloc] init];
		displaying = NO;
		fullScreenOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
							 [NSNumber numberWithInt:NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar], NSFullScreenModeApplicationPresentationOptions,
							 nil];
		ud = [NSUserDefaults standardUserDefaults];
	}
	return self;
}

-(void) dealloc
{
	[trackingArea release];
	[fullScreenOptions release];
	[dispLayer release];
	
	[super dealloc];
}

-(void) awakeFromNib
{
	// 设定LayerHost，现在只Host一个Layer
	[self setWantsLayer:YES];
	[self setLayer:dispLayer];
	
	// 通知dispView接受mplayer的渲染通知
	[playerController setDelegateForMPlayer:self];
	
	// 默认的全屏的DisplayID
	fullScrnDevID = [[[[NSScreen mainScreen] deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
	
	// 设定可以接受Drag Files
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,nil]];
	
	[[self window] setContentMinSize:NSMakeSize(400, 400)];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event 
{ return YES; }

-(BOOL) acceptsFirstResponder
{ return YES; }

-(void) mouseMoved:(NSEvent *)theEvent
{
	if (NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil], self.bounds)) {
		[controlUI showUp];
		[controlUI updateHintTime];
	}
}

- (void)mouseDragged:(NSEvent *)event
{	
	switch ([event modifierFlags] & (NSShiftKeyMask| NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask)) {
		case kSCMDragSubPosModifierFlagMask:
			// 改变Sub Position
			// 目前在ass enable的情况下不能工作
			[controlUI changeSubPosBy:[NSNumber numberWithFloat:([event deltaY] * 2) / self.bounds.size.height]];
			break;
		case kSCMDragAudioBalanceModifierFlagMask:
			// 这个也基本不能工作
			[controlUI changeAudioBalanceBy:[NSNumber numberWithFloat:([event deltaX] * 2) / self.bounds.size.width]];
			break;
		case 0:
			if (![self isInFullScreenMode]) {
				// 全屏的时候不能移动屏幕
				NSPoint winOrg = [[self window] frame].origin;
				
				winOrg.x += [event deltaX];
				winOrg.y -= [event deltaY];
				
				[[self window] setFrameOrigin:winOrg];
			}
			break;
		default:
			break;
	}
}

-(void) mouseUp:(NSEvent *)theEvent
{
	if ([theEvent clickCount] == 2) {
		switch ([theEvent modifierFlags] & (NSShiftKeyMask| NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask)) {
			case kSCMDragAudioBalanceModifierFlagMask:
				[controlUI changeAudioBalanceBy:nil];
				break;
			case 0:
				[controlUI performKeyEquivalent:[NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0, 0) modifierFlags:0 timestamp:0
															 windowNumber:0 context:nil
															   characters:kSCMFullScrnKeyEquivalent
											  charactersIgnoringModifiers:kSCMFullScrnKeyEquivalent
																isARepeat:NO keyCode:0]];
				break;
			default:
				break;
		}
	}
}

-(void) mouseEntered:(NSEvent *)theEvent
{
	[controlUI showUp];
}
-(void) mouseExited:(NSEvent *)theEvent
{
	if (![self isInFullScreenMode]) {
		// 全屏模式下，不那么积极的
		[controlUI doHide];
	}
}

-(void) keyDown:(NSEvent *)theEvent
{
	if (![shortCutManager processKeyDown:theEvent]) {
		[super keyDown:theEvent];
	}
}

-(NSSize) calculateContentSize
{
	const DisplayFormat *pf = [dispLayer getDisplayFormat];
	
	NSWindow *win = [self window];
	
	// 如果现在是没有显示的状态，那么返回当前的content size
	if (pf->width == 0) {
		return [[win contentView] bounds].size;
	}
	
	// 在播放中，有合法的尺寸
	NSSize sz = NSMakeSize(pf->width, ((CGFloat)(pf->width))/(pf->aspect));
	
	NSSize sizeMin = [[self window] contentMinSize];
	
	if ((sz.height < sizeMin.height) && (sz.width < sizeMin.width)) {
		// 现在的窗口最小原则是，不能全都小于最小值，有一个是可以的
		if ((sizeMin.width * sz.height) < (sizeMin.height * sz.width)) {
			// 横图
			sz.height = sizeMin.width * sz.height / sz.width;
			sz.width = sizeMin.width;
		} else {
			// 竖图
			sz.width = sizeMin.height * sz.width / sz.height;
			sz.height = sizeMin.height;
		}
	}
	return sz;
}

-(void) magnifyWithEvent:(NSEvent *)event
{
	if (![self isInFullScreenMode]) {
		// 得到能够放大的最大frame
		NSRect rcLimit = [[[self window] screen] visibleFrame];
		// 得到现在的content的size，要保持比例
		NSSize sz = [[[self window] contentView] bounds].size;
		// 得到window的最小size
		NSSize szMin = [[self window] minSize];
		
		NSRect rcWin = [[self window] frame];
		// 得到图像的比例
		// displayingがTRUEになったら、width, heightがOになるわけが無い
		const DisplayFormat* fmt = [dispLayer getDisplayFormat];
		
		// 得到需要缩放的content的size
		rcWin.size.height = sz.height * ([event magnification] +1.0);
		
		if (fmt->width == 0) {
			// 如果不是在播放状态，那么就根据当前的比例进行缩放
			rcWin.size.width = sz.width * ([event magnification] +1.0);
		} else {
			// 如果正在播放，那么根据影片的比例进行缩放
			rcWin.size.width = rcWin.size.height * fmt->aspect;
		}

		// 保持中心不变反算出窗口的
		rcWin.origin.x -= ((rcWin.size.width - sz.width)/2);
		rcWin.origin.y -= ((rcWin.size.height-sz.height)/2);
		
		rcWin = [[self window] frameRectForContentRect:rcWin];
		
		if (((rcWin.size.width >= szMin.width) || (rcWin.size.height >= szMin.height)) &&
			(rcWin.size.width < rcLimit.size.width) && (rcWin.size.height < rcLimit.size.height)) {
			[[self window] setFrame:rcWin display:YES];
		}
	}
}

-(void) swipeWithEvent:(NSEvent *)event
{
	CGFloat x = [event deltaX];
	CGFloat y = [event deltaY];
	unichar key;
	
	if (x < 0) {
		key = NSRightArrowFunctionKey;
	} else if (x > 0) {
		key = NSLeftArrowFunctionKey;
	} else if (y > 0) {
		key = NSUpArrowFunctionKey;
	} else if (y < 0) {
		key = NSDownArrowFunctionKey;
	} else {
		key = 0;
	}

	if (key) {
		[shortCutManager processKeyDown:[NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0, 0) modifierFlags:0 timestamp:0
													 windowNumber:0 context:nil
													   characters:nil
									  charactersIgnoringModifiers:[NSString stringWithCharacters:&key length:1]
														isARepeat:NO keyCode:0]];
	}
}

-(IBAction) writeSnapshotToFile:(id)sender
{
	if (displaying)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		// 得到图像数据
		CIImage *snapshot = [dispLayer snapshot];
		
		if (snapshot != nil) {
			// 得到图像的Rep
			NSBitmapImageRep *imRep = [[NSBitmapImageRep alloc] initWithCIImage:snapshot];
			// 设定这个Rep的存储方式
			NSData *imData = [NSBitmapImageRep representationOfImageRepsInArray:[NSArray arrayWithObject:imRep]
																	  usingType:NSPNGFileType
																	 properties:nil];
			// 得到存储文件夹
			NSString *savePath = [ud stringForKey:kUDKeySnapshotSavePath];
			
			// 如果是默认路径，那么就更换为绝对地址
			if ([savePath isEqualToString:kSnapshotSaveDefaultPath]) {
				savePath = [savePath stringByExpandingTildeInPath];
			}
			// 创建文件名
			// 修改文件名中的：，因为：无法作为文件名存储
			savePath = [NSString stringWithFormat:@"%@/%@_%@.png",
						savePath, 
						[[playerController.lastPlayedPath lastPathComponent] stringByDeletingPathExtension],
						[[NSDateFormatter localizedStringFromDate:[NSDate date]
														dateStyle:NSDateFormatterMediumStyle
														timeStyle:NSDateFormatterMediumStyle] 
						 stringByReplacingOccurrencesOfString:@":" withString:@"."]];							   
			// 写文件
			[imData writeToFile:savePath atomically:YES];
			[imRep release];
		}
		[pool release];
	}
}

-(BOOL) toggleFullScreen
{
	NSWindow *win = [self window];

	// ！注意：这里的显示状态和mplayer的播放状态时不一样的，比如，mplayer在MP3的时候，播放状态为YES，显示状态为NO
	if ([self isInFullScreenMode]) {
		// 应该退出全屏
		// 无论否在显示都可以退出全屏
		[self exitFullScreenModeWithOptions:fullScreenOptions];
		
		// 如果是连续全屏播放的话，是不会设定window的size的
		// 这样会有可能退出全屏的时候是一个不对的size
		// 这里会设定window的size，但是如果是播放关闭的状态退出播放，得到的size就是当前content的size
		if (shouldResize) {
			shouldResize = NO;
			[win setContentSize:[self calculateContentSize]];
		}		
		// 必须要在退出全屏之后才能设定window level
		[self setPlayerWindowLevel];
		// 全屏的时候直接关闭会崩溃
		if (playerController.playerState != kMPCStoppedState) {
			[win makeFirstResponder:self];
		}
	} else if (displaying) {
		// 应该进入全屏
		// 只有在显示图像的时候才能进入全屏
		// 进入全屏前，将window强制设定为普通mode，否则之后程序切换就无法正常
		[win setLevel:NSNormalWindowLevel];
		
		NSScreen *chosenScreen = [win screen];
		
		[self enterFullScreenMode:chosenScreen withOptions:fullScreenOptions];
		
		fullScrnDevID = [[[chosenScreen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
		
		// 得到screen的分辨率，并和播放中的图像进行比较
		// 知道是横图还是竖图
		NSSize sz = [chosenScreen frame].size;
		const DisplayFormat *pf = [dispLayer getDisplayFormat];
		
		[controlUI setFillScreenMode:((sz.height * (pf->aspect) >= sz.width)?kFillScreenButtonImageUBKey:kFillScreenButtonImageLRKey)
							   state:([dispLayer fillScreen])?NSOnState:NSOffState];
		// 这里不需要调用
		// [self setPlayerWindowLevel];
	} else {
		return NO;
	}
	// 暂停的时候能够正确显示
	[dispLayer setNeedsDisplay];
	return YES;
}

-(BOOL) toggleFillScreen
{
	[dispLayer setFillScreen: ![dispLayer fillScreen]];
	// 暂停的时候能够正确显示
	[dispLayer setNeedsDisplay];
	return [dispLayer fillScreen];
}

-(void) setPlayerWindowLevel
{
	if (![self isInFullScreenMode]) {
		int onTopMode = [ud integerForKey:kUDKeyOnTopMode];

		if ((onTopMode == kOnTopModeAlways) || 
			((onTopMode == kOnTopModePlaying) && (playerController.playerState == kMPCPlayingState))
			) {
			[[self window] setLevel: NSTornOffMenuWindowLevel];
		} else {
			[[self window] setLevel: NSNormalWindowLevel];
		}
	}
}

///////////////////////////////////for dragging/////////////////////////////////////////
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	
    if ( [[pboard types] containsObject:NSFilenamesPboardType] && (sourceDragMask & NSDragOperationCopy)) {
		return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	
	if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
		if (sourceDragMask & NSDragOperationCopy) {
			[playerController playMedia:[NSURL fileURLWithPath:[[pboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0] isDirectory:NO]];
		}
	}
	return YES;
}
///////////////////////////////////!!!!!!!!!!!!!!!!这三个方法是调用在工作线程上的，如果要操作界面，那么要小心!!!!!!!!!!!!!!!!!!!!!!!!!/////////////////////////////////////////
-(int) startWithWidth:(int) width height:(int) height pixelFormat:(OSType) pixelFormat aspect:(int) aspect from:(id)sender
{
	if ([dispLayer startWithWidth:width 
						   height:height
					  pixelFormat:pixelFormat
						   aspect:aspect] == 1) {
		displaying = YES;
		
		[self performSelectorOnMainThread:@selector(adjustWindowSizeAndAspectRatio) withObject:nil waitUntilDone:YES];

		if ([ud boolForKey:kUDKeyStartByFullScreen] && (![self isInFullScreenMode])) {
			[self performKeyEquivalent:[NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0, 0) modifierFlags:0 timestamp:0
													windowNumber:0 context:nil
													  characters:kSCMFullScrnKeyEquivalent
									 charactersIgnoringModifiers:kSCMFullScrnKeyEquivalent
													   isARepeat:NO keyCode:0]];
		}
		return 1;
	}
	return 0;
}

-(void) adjustWindowSizeAndAspectRatio
{
	NSWindow *win = [self window];
	NSSize sz;
	
	if ([self isInFullScreenMode]) {
		// 如果正在全屏，那么将设定窗口size的工作放到退出全屏的时候进行
		shouldResize = YES;
		
		// 如果是全屏开始的，那么还需要设定ControlUI的FillScreen状态
		// 全屏的时候，view的size和screen的size是一样的
		sz = [self bounds].size;
		const DisplayFormat *pf = [dispLayer getDisplayFormat];
		[controlUI setFillScreenMode:((sz.height * (pf->aspect) >= sz.width)?kFillScreenButtonImageUBKey:kFillScreenButtonImageLRKey)
							   state:([dispLayer fillScreen])?NSOnState:NSOffState];
	} else {
		// 如果没有在全屏
		sz = [self calculateContentSize];
		
		[win setContentSize:sz];
		[win setContentAspectRatio:sz];
	
		[win makeKeyAndOrderFront:self];
	}
	
	[controlUI displayStarted];
}

-(void) draw:(void*)imageData from:(id)sender
{
	[dispLayer draw:imageData];
}

-(void) stop:(id)sender
{
	[dispLayer stop];

	// 这个时候必须保证在推出全屏之后设为NO，因为切换全屏会参照现在displaying状态，NO的时候不动作
	displaying = NO;
	[controlUI displayStopped];
}

@end
