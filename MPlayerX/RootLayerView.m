/*
 * MPlayerX - RootLayerView.m
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

#import <Quartz/Quartz.h>
#import "def.h"
#import "RootLayerView.h"
#import "DisplayLayer.h"
#import "ControlUIView.h"
#import "PlayerController.h"
#import "ShortCutManager.h"
#import "OsdText.h"
#import "VideoTunerController.h"
#import "TitleView.h"

#define kOnTopModeNormal		(0)
#define kOnTopModeAlways		(1)
#define kOnTopModePlaying		(2)

#define kSnapshotSaveDefaultPath	(@"~/Desktop")

@interface RootLayerView (RootLayerViewInternal)
-(NSSize) calculateContentSize:(NSSize)refSize;
-(void) adjustWindowSizeAndAspectRatio:(NSValue*) sizeVal;
-(void) setupLayers;
-(void) reorderSubviews;
-(void) playBackFinalized:(NSNotification*)notif;
-(void) playBackStopped:(NSNotification*)notif;
-(void) playBackStarted:(NSNotification*)notif;
-(void) playBackOpened:(NSNotification*)notif;
@end

@implementation RootLayerView

@synthesize fullScrnDevID;
@synthesize lockAspectRatio;

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithInt:kOnTopModePlaying], kUDKeyOnTopMode,
					   kSnapshotSaveDefaultPath, kUDKeySnapshotSavePath,
					   [NSNumber numberWithBool:NO], kUDKeyStartByFullScreen,
					   [NSNumber numberWithBool:YES], kUDKeyFullScreenKeepOther,
					   [NSNumber numberWithBool:NO], kUDKeyQuitOnClose,
					   [NSNumber numberWithBool:YES], kUDKeyCloseWindowWhenStopped,
					   nil]];
}

#pragma mark Init/Dealloc
-(id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder]) {
		ud = [NSUserDefaults standardUserDefaults];
		notifCenter = [NSNotificationCenter defaultCenter];
		
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
							 [NSNumber numberWithBool:![ud boolForKey:kUDKeyFullScreenKeepOther]], NSFullScreenModeAllScreens,
							 nil];

		lockAspectRatio = YES;
		dragShouldResize = NO;
	}
	return self;
}

-(void) dealloc
{
	[notifCenter removeObserver:self];
	
	[self removeTrackingArea:trackingArea];
	[trackingArea release];
	[fullScreenOptions release];
	[dispLayer release];
	[logo release];
	
	[super dealloc];
}

-(void) setupLayers
{
	// 设定LayerHost，现在只Host一个Layer
	[self setWantsLayer:YES];
	
	// 得到基本的rootLayer
	CALayer *root = [self layer];
	
	// 禁用修改尺寸的action
	[root setDelegate:self];

	// 背景颜色
	CGColorRef col =  CGColorCreateGenericGray(0.0, 1.0);
	[root setBackgroundColor:col];
	CGColorRelease(col);
	
	col = CGColorCreateGenericRGB(0.392, 0.643, 0.812, 0.75);
	[root setBorderColor:col];
	CGColorRelease(col);
	
	// 自动尺寸适应
	[root setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
	
	NSBundle *mainB = [NSBundle mainBundle];
	logo = [[NSBitmapImageRep alloc] initWithCIImage:
			[CIImage imageWithContentsOfURL:
			 [[mainB resourceURL] URLByAppendingPathComponent:@"logo.png"]]];
	[root setContentsGravity:kCAGravityCenter];
	[root setContents:(id)[logo CGImage]];
	
	// 默认添加dispLayer
	[root insertSublayer:dispLayer atIndex:0];
	
	// 通知DispLayer
	[dispLayer setBounds:[root bounds]];
	[dispLayer setPosition:CGPointMake(root.bounds.size.width/2, root.bounds.size.height/2)];
}
-(id<CAAction>) actionForLayer:(CALayer*)layer forKey:(NSString*)event
{ return ((id<CAAction>)[NSNull null]); }

-(void) reorderSubviews
{
	// 将ControlUI放在最上层以防止被覆盖
	[controlUI retain];
	[controlUI removeFromSuperviewWithoutNeedingDisplay];
	[self addSubview:controlUI positioned:NSWindowAbove	relativeTo:nil];
	[controlUI release];
	
	[titlebar retain];
	[titlebar removeFromSuperviewWithoutNeedingDisplay];
	[self addSubview:titlebar positioned:NSWindowAbove relativeTo:nil];
	[titlebar release];
}

-(void) awakeFromNib
{
	[self setupLayers];
	
	[self reorderSubviews];
	
	// 通知dispView接受mplayer的渲染通知
	[playerController setDisplayDelegateForMPlayer:self];
	
	// 默认的全屏的DisplayID
	fullScrnDevID = [[[[playerWindow screen] deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
	
	// 设定可以接受Drag Files
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,nil]];

	[VTController setLayer:dispLayer];
	
	[notifCenter addObserver:self selector:@selector(windowHasResized:)
						name:NSWindowDidResizeNotification object:playerWindow];
	
	[notifCenter addObserver:self selector:@selector(playBackOpened:)
						name:kMPCPlayOpenedNotification object:playerController];
	[notifCenter addObserver:self selector:@selector(playBackStarted:)
						name:kMPCPlayStartedNotification object:playerController];
	[notifCenter addObserver:self selector:@selector(playBackStopped:)
						name:kMPCPlayStoppedNotification object:playerController];
	[notifCenter addObserver:self selector:@selector(playBackFinalized:)
						name:kMPCPlayFinalizedNotification object:playerController];
}

-(void) playBackFinalized:(NSNotification*)notif
{
	if ([ud boolForKey:kUDKeyCloseWindowWhenStopped] && [playerWindow isVisible]) {
		[playerWindow orderOut:self];
	}
}

-(void) playBackStopped:(NSNotification*)notif
{
	[self setPlayerWindowLevel];
	[playerWindow setTitle:kMPCStringMPlayerX];
}

-(void) playBackStarted:(NSNotification*)notif
{
	[self setPlayerWindowLevel];

	if ([[[notif userInfo] objectForKey:kMPCPlayStartedAudioOnlyKey] boolValue]) {
		[playerWindow setContentSize:[playerWindow contentMinSize]];
		[playerWindow makeKeyAndOrderFront:nil];
	}
}

-(void) playBackOpened:(NSNotification*)notif
{
	NSURL *url = [[notif userInfo] objectForKey:kMPCPlayOpenedURLKey];
	if (url) {		
		if ([url isFileURL]) {
			[playerWindow setTitle:[[url path] lastPathComponent]];
		} else {
			[playerWindow setTitle:[[url absoluteString] lastPathComponent]];
		}
	} else {
		[playerWindow setTitle:kMPCStringMPlayerX];
	}
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

-(void)mouseDown:(NSEvent *)theEvent
{
	dragMousePos = [NSEvent mouseLocation];
	NSRect winRC = [playerWindow frame];
	
	dragShouldResize = ((NSMaxX(winRC) - dragMousePos.x < 16) && (dragMousePos.y - NSMinY(winRC) < 16))?YES:NO;
	
	// NSLog(@"mouseDown");
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
				NSPoint posNow = [NSEvent mouseLocation];
				NSPoint delta;
				delta.x = (posNow.x - dragMousePos.x);
				delta.y = (posNow.y - dragMousePos.y);
				dragMousePos = posNow;
				
				if (dragShouldResize) {
					NSRect winRC = [playerWindow frame];
					NSRect newFrame = NSMakeRect(winRC.origin.x,
												 posNow.y, 
												 posNow.x-winRC.origin.x,
												 winRC.size.height + winRC.origin.y - posNow.y);
					
					winRC.size = [playerWindow contentRectForFrameRect:newFrame].size;
					
					if (displaying && lockAspectRatio) {
						// there is video displaying
						winRC.size = [self calculateContentSize:winRC.size];
					} else {
						NSSize minSize = [playerWindow contentMinSize];
						
						winRC.size.width = MAX(winRC.size.width, minSize.width);
						winRC.size.height= MAX(winRC.size.height, minSize.height);
					}

					winRC.origin.y -= (winRC.size.height - [[playerWindow contentView] bounds].size.height);
					
					[playerWindow setFrame:[playerWindow frameRectForContentRect:winRC] display:YES];
					// NSLog(@"should resize");
				} else {
					NSPoint winPos = [playerWindow frame].origin;
					winPos.x += delta.x;
					winPos.y += delta.y;
					[playerWindow setFrameOrigin:winPos];
					// NSLog(@"should move");
				}
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
	// do not use the playerWindow, since when fullscreen the window holds self is not playerWindow
	[[self window] makeFirstResponder:self];
	// NSLog(@"mouseUp");
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
		// 如果shortcut manager不处理这个evetn的话，那么就按照默认的流程
		[super keyDown:theEvent];
	}
}

-(void)scrollWheel:(NSEvent *)theEvent
{
	float x, y;
	x = [theEvent deltaX];
	y = [theEvent deltaY];
	
	if (abs(x) > (abs(y)*2)) {
		
	} else if ((abs(x)*2) < abs(y)) {
		[controlUI changeVolumeBy:[NSNumber numberWithFloat:y*0.2]];
	}
}

-(void) setLockAspectRatio:(BOOL) lock
{
	if (lock != lockAspectRatio) {
		lockAspectRatio = lock;
		
		if (lockAspectRatio) {
			// 如果锁定 aspect ratio的话，那么就按照现在的window的
			NSSize sz = [self bounds].size;
			
			[playerWindow setContentAspectRatio:sz];
			[dispLayer setExternalAspectRatio:(sz.width/sz.height)];
		} else {
			[playerWindow setContentResizeIncrements:NSMakeSize(1.0, 1.0)];
		}
	}
}

-(void) resetAspectRatio
{
	// 如果是全屏，playerWindow是否还拥有rootLayerView不知道
	// 但是全屏的时候并不会立即调整窗口的大小，而是会等推出全屏的时候再调整
	// 如果不是全屏，那么根据现在的size得到最合适的size
	[self adjustWindowSizeAndAspectRatio:[NSValue valueWithSize:[[playerWindow contentView] bounds].size]];
}

-(void) windowHasResized:(NSNotification *)notification
{
	if (!lockAspectRatio) {
		// 如果没有锁住aspect ratio
		NSSize sz = [self bounds].size;
		[dispLayer setExternalAspectRatio:(sz.width/sz.height)];
	}
}

-(NSSize) calculateContentSize:(NSSize)refSize
{
	NSSize dispSize = [dispLayer displaySize];
	CGFloat aspectRatio = [dispLayer aspectRatio];
	
	NSSize screenContentSize = [playerWindow contentRectForFrameRect:[[playerWindow screen] visibleFrame]].size;
	NSSize minSize = [playerWindow contentMinSize];
	
	if ((refSize.width < 0) || (refSize.height < 0)) {
		// 非法尺寸
		if (aspectRatio <= 0) {
			// 没有在播放
			refSize = [[playerWindow contentView] bounds].size;
		} else {
			// 在播放就用影片尺寸
			refSize.height = dispSize.height;
			refSize.width = refSize.height * aspectRatio;
		}
	}
	
	refSize.width  = MAX(minSize.width, MIN(screenContentSize.width, refSize.width));
	refSize.height = MAX(minSize.height, MIN(screenContentSize.height, refSize.height));
	
	if (aspectRatio > 0) {
		if (refSize.width > (refSize.height * aspectRatio)) {
			// 现在的movie是竖图
			refSize.width = refSize.height*aspectRatio;
		} else {
			// 现在的movie是横图
			refSize.height = refSize.width/aspectRatio;
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
			// 如果y方向超出了屏幕范围
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

-(void) refreshFullscreenMode
{
	[fullScreenOptions release];
	fullScreenOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
						 [NSNumber numberWithInt:NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar], NSFullScreenModeApplicationPresentationOptions,
						 [NSNumber numberWithBool:![ud boolForKey:kUDKeyFullScreenKeepOther]], NSFullScreenModeAllScreens,
						 nil];	
}

-(BOOL) toggleFullScreen
{
	// ！注意：这里的显示状态和mplayer的播放状态时不一样的，比如，mplayer在MP3的时候，播放状态为YES，显示状态为NO
	if ([self isInFullScreenMode]) {
		// 无论否在显示都可以退出全屏

		[self exitFullScreenModeWithOptions:fullScreenOptions];
		
		// 必须砸退出全屏的时候再设定
		// 在退出全屏之前，这个view并不属于window，设定contentsize不起作用
		if (shouldResize) {
			shouldResize = NO;
			NSSize sz = [self calculateContentSize:[[playerWindow contentView] bounds].size];
			
			NSPoint pos = [playerWindow frame].origin;
			NSSize orgSz = [[playerWindow contentView] bounds].size;
			
			pos.x += (orgSz.width - sz.width)  / 2;
			pos.y += (orgSz.height - sz.height)/ 2;
			
			[playerWindow setFrameOrigin:pos];

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
		
		// 强制Lock Aspect Ratio
		[self setLockAspectRatio:YES];

		// 得到window目前所在的screen
		NSScreen *chosenScreen = [playerWindow screen];
		
		[self enterFullScreenMode:chosenScreen withOptions:fullScreenOptions];
		
		fullScrnDevID = [[[chosenScreen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
		
		// 得到screen的分辨率，并和播放中的图像进行比较
		// 知道是横图还是竖图
		NSSize sz = [chosenScreen frame].size;
		
		[controlUI setFillScreenMode:(((sz.height * [dispLayer aspectRatio]) >= sz.width)?kFillScreenButtonImageUBKey:kFillScreenButtonImageLRKey)
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
		[[self layer] setBorderWidth:6.0];
		return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
	[[self layer] setBorderWidth:0.0];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	
	if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
		if (sourceDragMask & NSDragOperationCopy) {
			[[self layer] setBorderWidth:0.0];
			[playerController loadFiles:[pboard propertyListForType:NSFilenamesPboardType] fromLocal:YES];
		}
	}
	return YES;
}
///////////////////////////////////!!!!!!!!!!!!!!!!这三个方法是调用在工作线程上的，如果要操作界面，那么要小心!!!!!!!!!!!!!!!!!!!!!!!!!/////////////////////////////////////////
-(int) startWithWidth:(int) width height:(int) height pixelFormat:(OSType) pixelFormat aspect:(int) aspect from:(id)sender
{
	if ([dispLayer startWithWidth:width height:height pixelFormat:pixelFormat aspect:aspect] == 1) {
		displaying = YES;
		
		[VTController resetFilters:self];

		[self performSelectorOnMainThread:@selector(adjustWindowSizeAndAspectRatio:) withObject:[NSValue valueWithSize:NSMakeSize(-1, -1)] waitUntilDone:YES];

		[controlUI displayStarted];
		
		if ([ud boolForKey:kUDKeyStartByFullScreen] && (![self isInFullScreenMode])) {
			[self performSelectorOnMainThread:@selector(performKeyEquivalent:)
								   withObject:[NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0, 0) modifierFlags:0 timestamp:0
														   windowNumber:0 context:nil
															 characters:kSCMFullScrnKeyEquivalent
											charactersIgnoringModifiers:kSCMFullScrnKeyEquivalent
															  isARepeat:NO keyCode:0]
								waitUntilDone:NO];
		}
		return 1;
	}
	return 0;
}

-(void) adjustWindowSizeAndAspectRatio:(NSValue*) sizeVal
{
	NSSize sz;

	// 调用该函数会使DispLayer锁定并且窗口的比例也会锁定
	// 因此在这里设定lock是安全的
	lockAspectRatio = YES;
	// 虽然如果是全屏的话，是无法调用设定窗口的代码，但是全屏的时候无法改变窗口的size
	[dispLayer setExternalAspectRatio:kDisplayAscpectRatioInvalid];
	
	if ([self isInFullScreenMode]) {
		// 如果正在全屏，那么将设定窗口size的工作放到退出全屏的时候进行
		// 必须砸退出全屏的时候再设定
		// 在退出全屏之前，这个view并不属于window，设定contentsize不起作用
		shouldResize = YES;
		
		// 如果是全屏开始的，那么还需要设定ControlUI的FillScreen状态
		// 全屏的时候，view的size和screen的size是一样的
		sz = [self bounds].size;
		
		CGFloat aspectRatio = [dispLayer aspectRatio];
		[controlUI setFillScreenMode:(((sz.height * aspectRatio) >= sz.width)?kFillScreenButtonImageUBKey:kFillScreenButtonImageLRKey)
							   state:([dispLayer fillScreen])?NSOnState:NSOffState];
	} else {
		// 如果没有在全屏
		sz = [self calculateContentSize:[sizeVal sizeValue]];
		
		NSPoint pos = [playerWindow frame].origin;
		NSSize orgSz = [[playerWindow contentView] bounds].size;
		
		pos.x += (orgSz.width - sz.width)  / 2;
		pos.y += (orgSz.height - sz.height)/ 2;
		
		[playerWindow setFrameOrigin:pos];
		
		[playerWindow setContentSize:sz];
		[playerWindow setContentAspectRatio:sz];
	
		if (![playerWindow isVisible]) {
			[[self layer] setContents:nil];
			[playerWindow makeKeyAndOrderFront:self];
		}
	}
}

-(void) draw:(void*)imageData from:(id)sender
{
	[dispLayer draw:imageData];
}

-(void) stop:(id)sender
{
	[dispLayer stop];

	displaying = NO;
	[controlUI displayStopped];
	[playerWindow setContentResizeIncrements:NSMakeSize(1.0, 1.0)];
	[[self layer] setContents:(id)[logo CGImage]];
}

///////////////////////////////////////////PlayerWindow delegate//////////////////////////////////////////////
-(void) windowWillClose:(NSNotification *)notification
{
	if ([ud boolForKey:kUDKeyQuitOnClose]) {
		[NSApp terminate:nil];
	} else {
		[playerController stop];
	}
}

-(BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame
{
	return (displaying && (![window isZoomed]));
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
{
	if ((window == playerWindow)) {
		NSRect scrnRect = [[window screen] frame];

		newFrame.size = [self calculateContentSize:scrnRect.size];
		newFrame = [window frameRectForContentRect:newFrame];
		newFrame.origin.x = (scrnRect.size.width - newFrame.size.width)/2;
		newFrame.origin.y = (scrnRect.size.height- newFrame.size.height)/2;
	}
	return newFrame;
}

@end
