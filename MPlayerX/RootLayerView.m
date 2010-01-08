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
#import "AppController.h"
#import "ShortCutManager.h"

#define kOnTopModeNormal		(0)
#define kOnTopModeAlways		(1)
#define kOnTopModePlaying		(2)

#define kSnapshotSaveDefaultPath	(@"~/Desktop")

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
		dispLayer = [[DisplayLayer alloc] init];
		displaying = NO;
		fullScreenOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
							 [NSNumber numberWithInt:NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar], NSFullScreenModeApplicationPresentationOptions,
							 nil];
	}
	return self;
}

-(void) dealloc
{
	[fullScreenOptions release];
	[dispLayer release];
	
	[super dealloc];
}

-(void) awakeFromNib
{
	// 设定LayerHost，现在只Host一个Layer
	[self setWantsLayer:YES];
	[self setLayer:dispLayer];
	
	// 默认的全屏的DisplayID
	fullScrnDevID = [[[[NSScreen mainScreen] deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
	
	// 设定可以接受Drag Files
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,nil]];
	
	// 设定window可以接受MouseMoved Event
	[[self window] setAcceptsMouseMovedEvents:YES];
	
	// 设定window的level
	[self setPlayerWindowLevel];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event 
{ return YES; }

-(BOOL) acceptsFirstResponder
{ return YES; }

-(void) mouseMoved:(NSEvent *)theEvent
{
	if (NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil], self.bounds)) {
		[controlUI showUp];
		[controlUI mouseMoved:theEvent];
	}
}

- (void)mouseDragged:(NSEvent *)event
{
	if ([controlUI isFullScreen] == NSOffState) {
		// 全屏的时候不能移动屏幕
		NSPoint winOrg = [[self window] frame].origin;
		
		winOrg.x += [event deltaX];
		winOrg.y -= [event deltaY];
		
		[[self window] setFrameOrigin:winOrg];
	}
}

-(void) keyDown:(NSEvent *)theEvent
{
	if (![shortCutManager processKeyDown:theEvent]) {
		[super keyDown:theEvent];
	}
}

-(void) magnifyWithEvent:(NSEvent *)event
{
	if (displaying && ([controlUI isFullScreen] == NSOffState)) {
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
		rcWin.size.width = rcWin.size.height * fmt->aspect;

		// 保持中心不变反算出窗口的
		rcWin.origin.x -= ((rcWin.size.width - sz.width)/2);
		rcWin.origin.y -= ((rcWin.size.height-sz.height)/2);
		
		rcWin = [[self window] frameRectForContentRect:rcWin];
		
		if ((rcWin.size.width > szMin.width) && (rcWin.size.height > szMin.height) &&
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
			NSString *savePath = [[NSUserDefaults standardUserDefaults] stringForKey:kUDKeySnapshotSavePath];
			
			// 如果是默认路径，那么就更换为绝对地址
			if ([savePath isEqualToString:kSnapshotSaveDefaultPath]) {
				savePath = [savePath stringByExpandingTildeInPath];
			}
			// 创建文件名
			// 修改文件名中的：，因为：无法作为文件名存储
			savePath = [NSString stringWithFormat:@"%@/%@_%@.png",
						savePath, 
						[[appController.lastPlayedPath lastPathComponent] stringByDeletingPathExtension],
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
	if (displaying) {
		// 处于显示状态
		// ！注意：这里的显示状态和mplayer的播放状态时不一样的，比如，mplayer在MP3的时候，播放状态为YES，显示状态为NO
		if ([controlUI isFullScreen] == NSOnState) {
			// should enter the full screen
			// 进入全屏前，将window强制设定为普通mode，否则之后程序切换就无法正常
			[[self window] setLevel:NSNormalWindowLevel];
			
			NSScreen *chosenScreen = [[self window] screen];
			
			[self enterFullScreenMode:chosenScreen withOptions:fullScreenOptions];
			
			fullScrnDevID = [[[chosenScreen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
			
			// 得到screen的分辨率，并和播放中的图像进行比较
			// 知道是横图还是竖图
			NSSize sz = [chosenScreen frame].size;
			const DisplayFormat *pf = [dispLayer getDisplayFormat];
			
			[controlUI setFillScreenMode:((sz.height * (pf->aspect) >= sz.width)?kFillScreenButtonImageUBKey:kFillScreenButtonImageLRKey)
								   state:([dispLayer fillScreen])?NSOnState:NSOffState];
			// 这里不需要调用 [self setPlayerWindowLevel];
		} else {
			// should exit the full screen
			[self exitFullScreenModeWithOptions:fullScreenOptions];
			[[self window] makeFirstResponder:self];
			// 必须要在退出全屏之后才能设定window level
			[self setPlayerWindowLevel];
		}
		// 暂停的时候能够正确显示
		[dispLayer setNeedsDisplay];
		return YES;
	}
	return NO;
}

-(BOOL) toggleFillScreen
{
	if (displaying) {
		[dispLayer setFillScreen: ([controlUI isFillScreen] == NSOnState)?YES:NO];
		// 暂停的时候能够正确显示
		[dispLayer setNeedsDisplay];
	}
	return displaying;
}

-(void) setPlayerWindowLevel
{
	if ([controlUI isFullScreen] == NSOffState) {
		int onTopMode = [[NSUserDefaults standardUserDefaults] integerForKey:kUDKeyOnTopMode];

		if ((onTopMode == kOnTopModeAlways) || 
			((onTopMode == kOnTopModePlaying) && [appController.mplayer isPlaying] && (![appController.mplayer isPaused]))
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
			[appController playMedia:[NSURL fileURLWithPath:[[pboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0] isDirectory:NO]];
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

		[dispLayer setFillScreen: NO];
		const DisplayFormat *pf = [dispLayer getDisplayFormat];
		NSValue *szVal = [NSValue valueWithSize: NSMakeSize(pf->width, (pf->width)/(pf->aspect))];
		
		[self performSelectorOnMainThread:@selector(adjustWindowSizeAndAspectRatio:) withObject:szVal waitUntilDone:YES];

		[controlUI displayStarted];

		if ([[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyStartByFullScreen]) {
			if ([controlUI isFillScreen] == NSOffState) {
				[self performKeyEquivalent:[NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0, 0) modifierFlags:0 timestamp:0
														windowNumber:0 context:nil
														  characters:kSCMFullScrnKeyEquivalent
										 charactersIgnoringModifiers:kSCMFullScrnKeyEquivalent
														   isARepeat:NO keyCode:0]];
			}
		}
		return 1;
	}
	return 0;
}
-(void) adjustWindowSizeAndAspectRatio:(NSValue*) size
{
	NSSize sz = [size sizeValue];
	NSSize sizeMin = [[self window] contentMinSize];
	
	NSWindow *win = [self window];
	
	if ((sz.height < sizeMin.height) || (sz.width < sizeMin.width)) {
		if ((sizeMin.width * sz.height) < (sizeMin.height * sz.width)) {
			// 横图
			sz.width = sizeMin.height * sz.width / sz.height;
			sz.height = sizeMin.height;
		} else {
			// 竖图
			sz.height = sizeMin.width * sz.height / sz.width;
			sz.width = sizeMin.width;
		}
	}

	[win setContentSize:sz];
	[win setContentAspectRatio:sz];
	
	[win makeKeyAndOrderFront:self];
}

-(void) draw:(void*)imageData from:(id)sender
{
	[dispLayer draw:imageData];
}

-(void) stop:(id)sender
{
	if ([controlUI isFullScreen] == NSOnState) {
		// 这个方法里面会将FullScreen的状态设为NSOffState
		// 因为这个事件不是User发起的，是内部发起的，所以要先设定状态，再发message
		
		// 必须在controlUI退出全屏之后，fullScreenButton的状态才会变为OFF，然后再设定window level才能正确设定
		// setPlayerWindowLevel里面需要得到fullScreenButton的状态
		// 所以这个需要先调用
		[controlUI exitedFullScreen];
		
		[self performSelectorOnMainThread:@selector(toggleFullScreen) withObject:nil waitUntilDone:YES];
	}
	
	[dispLayer stop];

	// 这个时候必须保证在推出全屏之后设为NO，因为切换全屏会参照现在displaying状态，NO的时候不动作
	displaying = NO;
	[controlUI displayStopped];
}

@end
