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
-(NSSize) calculateContentSize:(NSSize)refSize;
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
-(id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder]) {
		trackingArea = [[NSTrackingArea alloc] initWithRect:NSInsetRect([self frame], 1, 1) 
													options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingAssumeInside
													  owner:self
												   userInfo:nil];
		[self addTrackingArea:trackingArea];
		shouldResize = NO;
		dispLayer = [[DisplayLayer alloc] init];
		displaying = NO;
		fullScreenOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
							 [NSNumber numberWithInt:NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar], NSFullScreenModeApplicationPresentationOptions,
							 [NSNumber numberWithBool:NO], NSFullScreenModeAllScreens,
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
	fullScrnDevID = [[[[playerWindow screen] deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
	
	// 设定可以接受Drag Files
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,nil]];
	
	[playerWindow setContentMinSize:NSMakeSize(400, 400)];
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
				NSPoint winOrg = [playerWindow frame].origin;
				
				winOrg.x += [event deltaX];
				winOrg.y -= [event deltaY];
				
				[playerWindow setFrameOrigin:winOrg];
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

-(NSSize) calculateContentSize:(NSSize)refSize
{
	const DisplayFormat *pf = [dispLayer getDisplayFormat];
	
	NSSize screenContentSize = [playerWindow contentRectForFrameRect:[[playerWindow screen] visibleFrame]].size;
	NSSize minSize = [playerWindow contentMinSize];
	
	if ((refSize.width < 0) || (refSize.height < 0)) {
		// 非法尺寸
		if (pf->width < 1) {
			// 没有在播放
			refSize = [[playerWindow contentView] bounds].size;
		} else {
			// 在播放就用影片尺寸
			refSize.height = pf->height;
			refSize.width = refSize.height * pf->aspect;
		}
	}
	
	refSize.width  = MAX(minSize.width, MIN(screenContentSize.width, refSize.width));
	refSize.height = MAX(minSize.height, MIN(screenContentSize.height, refSize.height));
	
	if (pf->width > 0) {
		if (refSize.width > (refSize.height * pf->aspect)) {
			// 现在的movie是竖图
			refSize.width = refSize.height*pf->aspect;
		} else {
			refSize.height = refSize.width/pf->aspect;
		}
	}
	return refSize;
}

-(void) magnifyWithEvent:(NSEvent *)event
{
	if (![self isInFullScreenMode]) {
		// 得到能够放大的最大frame
		NSRect rcLimit = [[playerWindow screen] visibleFrame];
		// 得到现在的content的size，要保持比例
		NSSize sz = [[playerWindow contentView] bounds].size;
		
		NSRect rcWin = [playerWindow frame];
		
		// 得到需要缩放的content的size
		rcWin.size.height = sz.height * ([event magnification] +1.0);
		rcWin.size.width = sz.width * ([event magnification] +1.0);
		
		rcWin.size = [self calculateContentSize:rcWin.size];
		
		// 保持中心不变反算出窗口的
		rcWin.origin.x -= ((rcWin.size.width - sz.width)/2);
		rcWin.origin.y -= ((rcWin.size.height-sz.height)/2);
		
		rcWin = [playerWindow frameRectForContentRect:rcWin];
		
		if ((rcWin.origin.y + rcWin.size.height) > (rcLimit.origin.y + rcLimit.size.height)) {
			rcWin.origin.y = rcLimit.origin.y + rcLimit.size.height - rcWin.size.height;
		}
		[playerWindow setFrame:rcWin display:YES];
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
			NSString *mediaPath = ([playerController.lastPlayedPath isFileURL])?([playerController.lastPlayedPath path]):([playerController.lastPlayedPath absoluteString]);
			// 创建文件名
			// 修改文件名中的：，因为：无法作为文件名存储
			savePath = [NSString stringWithFormat:@"%@/%@_%@.png",
						savePath, 
						[[mediaPath lastPathComponent] stringByDeletingPathExtension],
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
	// ！注意：这里的显示状态和mplayer的播放状态时不一样的，比如，mplayer在MP3的时候，播放状态为YES，显示状态为NO
	if ([self isInFullScreenMode]) {
		// 应该退出全屏
		// 无论否在显示都可以退出全屏

		[self exitFullScreenModeWithOptions:fullScreenOptions];
		// 必须砸退出全屏的时候再设定
		// 在退出全屏之前，这个view并不属于window，设定contentsize不起作用
		if (shouldResize) {
			shouldResize = NO;
			NSSize sz = [self calculateContentSize:[[playerWindow contentView] bounds].size];
			[playerWindow setContentSize:sz];
			[playerWindow setContentAspectRatio:sz];			
		}

		[playerWindow makeKeyAndOrderFront:self];
		[playerWindow makeFirstResponder:self];
		
		// 必须要在退出全屏之后才能设定window level
		[self setPlayerWindowLevel];
	} else if (displaying) {
		// 应该进入全屏
		// 只有在显示图像的时候才能进入全屏
		// 进入全屏前，将window强制设定为普通mode，否则之后程序切换就无法正常
		[playerWindow setLevel:NSNormalWindowLevel];
		
		NSScreen *chosenScreen = [playerWindow screen];
		
		[self enterFullScreenMode:chosenScreen withOptions:fullScreenOptions];
		
		fullScrnDevID = [[[chosenScreen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
		
		// 得到screen的分辨率，并和播放中的图像进行比较
		// 知道是横图还是竖图
		NSSize sz = [chosenScreen frame].size;
		const DisplayFormat *pf = [dispLayer getDisplayFormat];
		
		[controlUI setFillScreenMode:((sz.height * (pf->aspect) >= sz.width)?kFillScreenButtonImageUBKey:kFillScreenButtonImageLRKey)
							   state:([dispLayer fillScreen])?NSOnState:NSOffState];
		[playerWindow orderOut:self];
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
			[playerWindow setLevel: NSTornOffMenuWindowLevel];
		} else {
			[playerWindow setLevel: NSNormalWindowLevel];
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
			[playerController loadFiles:[pboard propertyListForType:NSFilenamesPboardType] fromLocal:YES];
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
		sz = [self calculateContentSize:NSMakeSize(-1, -1)];
		
		[playerWindow setContentSize:sz];
		[playerWindow setContentAspectRatio:sz];
	
		[playerWindow makeKeyAndOrderFront:self];
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
	[playerWindow setContentResizeIncrements:NSMakeSize(1.0, 1.0)];
}

@end
