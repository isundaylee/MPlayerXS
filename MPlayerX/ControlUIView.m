/*
 * MPlayerX - ControlUIView.m
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

#import "def.h"
#import "ControlUIView.h"
#import "RootLayerView.h"
#import "AppController.h"
#import "FloatWrapFormatter.h"
#import "ArrowTextField.h"
#import "ResizeIndicator.h"

#define BACKGROUND_ALPHA		(0.95)
#define CONTROL_CORNER_RADIUS	(8)

#define NUMOFVOLUMEIMAGES		(3)	//这个值是除了没有音量之后的image个数
#define AUTOHIDETIMEINTERNAL	(2)

#define LASTSTOPPEDTIMERATIO	(100)

@implementation ControlUIView

@synthesize autoHideTimeInterval;

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithFloat:100], kUDKeyVolume,
					   [NSNumber numberWithDouble:AUTOHIDETIMEINTERNAL], kUDKeyCtrlUIAutoHideTime,
					   nil]];
}

-(void) loadButtonImages
{
	// 通用资源
	NSString *resPath = [[NSBundle mainBundle] resourcePath];
	
	imVolNo			= [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", resPath, @"vol_no.pdf"]];
	imVolLow		= [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", resPath, @"vol_low.pdf"]];
	imVolMid		= [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", resPath, @"vol_mid.pdf"]];
	imVolHigh		= [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", resPath, @"vol_high.pdf"]];
	imFillScrnInLR	= [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", resPath, @"fillscreen_lr.pdf"]];
	imFillScrnOutLR	= [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", resPath, @"exitfillscreen_lr.pdf"]];
	imFillScrnInUB	= [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", resPath, @"fillscreen_ub.pdf"]];
	imFillScrnOutUB	= [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", resPath, @"exitfillscreen_ub.pdf"]];	
	
	// 初始化音量大小图标
	volumeButtonImages = [[NSArray alloc] initWithObjects:imVolNo, imVolLow, imVolMid, imVolHigh, nil];
	// fillScreenButton初期化
	fillScreenButtonAllImages =  [[NSDictionary alloc] initWithObjectsAndKeys: 
								  [NSArray arrayWithObjects:imFillScrnInLR, imFillScrnOutLR, nil], kFillScreenButtonImageLRKey,
								  [NSArray arrayWithObjects:imFillScrnInUB, imFillScrnOutUB, nil], kFillScreenButtonImageUBKey, 
								  nil];
}

-(void) setKeyEquivalents
{
	[volumeButton setKeyEquivalent:kSCMMuteKeyEquivalent];
	[playPauseButton setKeyEquivalent:kSCMPlayPauseKeyEquivalent];
	[fullScreenButton setKeyEquivalent:kSCMFullScrnKeyEquivalent];
	[fillScreenButton setKeyEquivalent:kSCMFillScrnKeyEquivalent];
	[toggleAcceButton setKeyEquivalent:kSCMAcceControlKeyEquivalent];
	[menuSnapshot setKeyEquivalent:kSCMSnapShotKeyEquivalent];
	[menuSwitchSub setKeyEquivalent:kSCMStepSubKeyEquivalent];
	
	[menuSubScaleInc setKeyEquivalentModifierMask:kSCMSubScaleIncreaseKeyEquivalentModifierFlagMask];
	[menuSubScaleInc setKeyEquivalent:kSCMSubScaleIncreaseKeyEquivalent];
	[menuSubScaleDec setKeyEquivalentModifierMask:kSCMSubScaleDecreaseKeyEquivalentModifierFlagMask];
	[menuSubScaleDec setKeyEquivalent:kSCMSubScaleDecreaseKeyEquivalent];
	
	[menuPlayFromLastStoppedPlace setKeyEquivalent:kSCMPlayFromLastStoppedKeyEquivalent];
	[menuPlayFromLastStoppedPlace setKeyEquivalentModifierMask:kSCMPlayFromLastStoppedKeyEquivalentModifierFlagMask];
}

- (void)awakeFromNib
{
	// 自身的设定
	[self setAlphaValue:BACKGROUND_ALPHA];
	
	fillGradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithCalibratedWhite:0.150 alpha:1], 0.0,
																  [NSColor colorWithCalibratedWhite:0.078 alpha:1], 0.35,
																  [NSColor colorWithCalibratedWhite:0.078 alpha:1], 1.0, nil];

	[self setKeyEquivalents];
	[self loadButtonImages];

	// 自动隐藏设定
	autoHideTimeInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:kUDKeyCtrlUIAutoHideTime];
	shouldHide = NO;
	autoHideTimer = [NSTimer scheduledTimerWithTimeInterval:autoHideTimeInterval
													 target:self
												   selector:@selector(tryToHide)
												   userInfo:nil
													repeats:YES];
	// 从userdefault中获得default 音量值
	[volumeSlider setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:kUDKeyVolume]];
	[self setVolume:volumeSlider];

	// 初始化时间显示slider和text
	timeFormatter = [[TimeFormatter alloc] init];
	[[timeText cell] setFormatter:timeFormatter];
	[timeText setStringValue:@""];
	[timeSlider setEnabled:NO];
	[hintTime setAlphaValue:0];
	
	// 初始状态是hide
	[fullScreenButton setHidden: YES];
	
	[fillScreenButton setHidden: YES];	
	NSArray *fillScrnBtnModeImages = [fillScreenButtonAllImages objectForKey:kFillScreenButtonImageUBKey];
	[fillScreenButton setImage: [fillScrnBtnModeImages objectAtIndex:0]];
	[fillScreenButton setAlternateImage:[fillScrnBtnModeImages objectAtIndex:1]];
	[fillScreenButton setState: NSOffState];
	
	floatWrapFormatter = [[FloatWrapFormatter alloc] init];
	[[speedText cell] setFormatter:floatWrapFormatter];
	[[subDelayText cell] setFormatter:floatWrapFormatter];
	[[audioDelayText cell] setFormatter:floatWrapFormatter];
	
	[speedText setStepValue:[[NSUserDefaults standardUserDefaults] floatForKey:kUDKeySpeedStep]];
	[subDelayText setStepValue:[[NSUserDefaults standardUserDefaults] floatForKey:kUDKeySubDelayStepTime]];
	[audioDelayText setStepValue:[[NSUserDefaults standardUserDefaults] floatForKey:kUDKeyAudioDelayStepTime]];

	subListMenu = [[NSMenu alloc] initWithTitle:@"SubListMenu"];
	[menuSwitchSub setSubmenu:subListMenu];
	[subListMenu setAutoenablesItems:NO];
	
	[menuSubScaleInc setTag:1];
	[menuSubScaleDec setTag:-1];
}

-(void) dealloc
{
	[autoHideTimer invalidate];
	
	[imVolNo release];
	[imVolLow release];
	[imVolMid release];
	[imVolHigh release];
	[imFillScrnInLR release];
	[imFillScrnOutLR release];
	[imFillScrnInUB release];
	[imFillScrnOutUB release];

	[fillScreenButtonAllImages release];
	[volumeButtonImages release];
	[timeFormatter release];
	[floatWrapFormatter release];
	
	[menuSwitchSub setSubmenu:nil];
	[subListMenu removeAllItems];
	[subListMenu release];

	[fillGradient release];
	
	[super dealloc];
}

////////////////////////////////////////////////AutoHideThings//////////////////////////////////////////////////
-(void) setAutoHideTimeInterval:(NSTimeInterval) ti
{
	if ((ti != autoHideTimeInterval) && (ti > 0)) {
		// 这个Timer没有retain，所以也不需要release
		[autoHideTimer invalidate];
		autoHideTimeInterval = ti;
		autoHideTimer = [NSTimer scheduledTimerWithTimeInterval:autoHideTimeInterval
														 target:self
													   selector:@selector(tryToHide)
													   userInfo:nil
														repeats:YES];
	}
}

-(void) tryToHide
{
	if (shouldHide) {
		// 这段代码是不能重进的，否则会不停的hidecursor
		if ([self alphaValue] > (BACKGROUND_ALPHA-0.05)) {
			// 得到鼠标在这个view的坐标
			NSPoint pos = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] 
									fromView:nil];
			// 如果不在这个View的话，那么就隐藏自己
			if (!NSPointInRect(pos, self.bounds)) {
				[self.animator setAlphaValue:0];
				
				// 如果是全屏模式也要隐藏鼠标
				if ([fullScreenButton state] == NSOnState) {
					CGDisplayHideCursor(dispView.fullScrnDevID);
				} else {
					// 不是全屏的话，隐藏resizeindicator
					// 全屏的话不管
					[rzIndicator.animator setAlphaValue:0];
				}
			}			
		}
	} else {
		shouldHide = YES;
	}
}

-(void) showUp
{
	shouldHide = NO;

	[self.animator setAlphaValue:BACKGROUND_ALPHA];

	if ([fullScreenButton state] == NSOnState) {
		// 全屏模式还要显示鼠标
		CGDisplayShowCursor(dispView.fullScrnDevID);
	} else {
		// 不是全屏模式的话，要显示resizeindicator
		// 全屏的时候不管
		[rzIndicator.animator setAlphaValue:1];
	}

}

////////////////////////////////////////////////Actions//////////////////////////////////////////////////
-(IBAction) togglePlayPause:(id)sender
{
	if (![appController togglePlayPause]) {
		// 如果失败的话，ControlUI回到停止状态
		[self playBackStopped];
	} else {
		[dispView setPlayerWindowLevel];
	}
}

-(IBAction) toggleMute:(id)sender
{
	BOOL mute = [appController toggleMute];
	
	// mplayer在暂停的时候不能mute，所以要根据返回值进行重新设定
	[volumeButton setState:(mute)?NSOnState:NSOffState];
	[volumeSlider setEnabled:(!mute)];
}

-(IBAction) setVolume:(id)sender
{
	if ([volumeSlider isEnabled]) {
		// 这里必须要从sender拿到floatValue，而不能直接从volumeSlider拿
		// 因为有可能是键盘快捷键，这个时候，ShortCutManager会发一个NSNumber作为sender过来
		float vol = [sender floatValue];
		vol = [appController setVolume:vol];
		
		[volumeSlider setFloatValue: vol];
		
		double max = [volumeSlider maxValue];
		int now = (int)((vol*NUMOFVOLUMEIMAGES + max -1)/max);
		[volumeButton setImage: [volumeButtonImages objectAtIndex: now]];
		
		// 将音量作为UserDefaults存储
		[[NSUserDefaults standardUserDefaults] setFloat:vol forKey:kUDKeyVolume];
	}
}

-(IBAction) seekTo:(id) sender
{
	// 这里并没有直接更新controlUI的代码
	// 因为controlUI会KVO mplayer.movieInfo.playingInfo.currentTime
	// appController的seekTo方法里会根据新设定的时间修改currentTime
	// 因此这里不用直接更新界面
	[appController seekTo:[timeSlider timeDest]];
}

-(IBAction) toggleFullScreen:(id)sender
{
	NSInteger fs = [fullScreenButton state];

	if ([dispView toggleFullScreen]) {
		// 成功
		if (fs == NSOnState) {
			// 进入全屏
			
			// fillScreenButton的Image设定之类的，
			// 在RootLayerView里面实现，因为设定这个需要比较多的参数
			// 会让接口变的很难看
			[fillScreenButton setHidden: NO];
			
			// 如果自己已经被hide了，那么就把鼠标也hide
			if ([self alphaValue] < (BACKGROUND_ALPHA-0.05)) {
				CGDisplayHideCursor(dispView.fullScrnDevID);
			}
			
			// 进入全屏，强制隐藏resizeindicator
			[rzIndicator.animator setAlphaValue:0];
		} else {
			// 退出全屏
			[self exitedFullScreen];
		}
	} else {
		// 失败
		[fullScreenButton setState: NSOffState];
	}
}

-(IBAction) toggleFillScreen:(id)sender
{
	if(![dispView toggleFillScreen]) {
		[fillScreenButton setHidden: YES];
		[fillScreenButton setState: NSOffState];
	}
}

-(IBAction) toggleAccessaryControls:(id)sender
{
	NSRect rcSelf = [self frame];
	if ([toggleAcceButton state] == NSOnState) {
		rcSelf.size.height += accessaryContainer.frame.size.height;
		rcSelf.origin.y -= MIN(rcSelf.origin.y, accessaryContainer.frame.size.height);
		
		[self.animator setFrame:rcSelf];
		[accessaryContainer.animator setHidden: NO];
		
	} else {
		[accessaryContainer.animator setHidden: YES];
		rcSelf.size.height -= accessaryContainer.frame.size.height;
		rcSelf.origin.y += accessaryContainer.frame.size.height;
		
		[self.animator setFrame:rcSelf];
	}
}

-(IBAction) changeSpeed:(id) sender
{
	[appController setSpeed:[sender floatValue]];
}

-(IBAction) changeAudioDelay:(id) sender
{
	[appController setAudioDelay:[sender floatValue]];	
}

-(IBAction) changeSubDelay:(id)sender
{
	[appController setSubDelay:[sender floatValue]];
}

-(IBAction) changeSubScale:(id)sender
{
	[appController changeSubScaleBy:[sender tag] * [[NSUserDefaults standardUserDefaults] floatForKey:kUDKeySubScaleStepValue]];
}

-(IBAction) stepSubtitles:(id)sender
{
	int selectedTag = -2;
	NSMenuItem* mItem;
	
	// 找到目前被选中的字幕
	for (mItem in [subListMenu itemArray]) {
		if ([mItem state] == NSOnState) {
			selectedTag = [mItem tag];
			[mItem setState:NSOffState];
			break;
		}
	}
	// 得到下一个字幕的tag
	// 如果没有一个菜单选项被选中，那么就选中隐藏显示字幕
	selectedTag++;
	
	if (!(mItem = [subListMenu itemWithTag:selectedTag])) {
		// 如果是字幕的最后一项，那么就轮到隐藏字幕菜单选项
		mItem = [subListMenu itemWithTag:-1];
	}
	
	[appController setSubtitle:[mItem tag]];

	[mItem setState:NSOnState];
}

-(IBAction) setSubWithID:(id)sender
{
	[appController setSubtitle:[sender tag]];
	
	for (NSMenuItem* mItem in [subListMenu itemArray]) {
		[mItem setState:NSOffState];
	}
	[sender setState:NSOnState];
}

-(IBAction) playFromLastStopped:(id)sender
{
	float tm = [sender tag];
	tm = MAX(0, (tm / LASTSTOPPEDTIMERATIO) - 5); // 给大家一个5秒钟的回忆时间
	
	[timeSlider setTimeDest:tm];
	[self seekTo:timeSlider];
}

////////////////////////////////////////////////FullscreenThings//////////////////////////////////////////////////
-(NSInteger) isFullScreen
{
	return [fullScreenButton state];
}

-(NSInteger) isFillScreen
{
	return [fillScreenButton state];
}

-(void) setFillScreenMode:(NSString*)modeKey state:(NSInteger) state
{
	NSArray *fillScrnBtnModeImages = [fillScreenButtonAllImages objectForKey:modeKey];
	
	if (fillScrnBtnModeImages) {
		[fillScreenButton setImage:[fillScrnBtnModeImages objectAtIndex:0]];
		[fillScreenButton setAlternateImage:[fillScrnBtnModeImages objectAtIndex:1]];
	}	
	[fillScreenButton setState:state];
}

-(void) exitedFullScreen
{
	CGDisplayShowCursor(dispView.fullScrnDevID);
	[fullScreenButton setState: NSOffState];
	[fillScreenButton setHidden: YES];
	
	if ([self alphaValue] > (BACKGROUND_ALPHA-0.05)) {
		// 如果controlUI没有隐藏，那么显示resizeindiccator
		[rzIndicator.animator setAlphaValue:1];
	}
}

////////////////////////////////////////////////displayThings//////////////////////////////////////////////////
-(void) displayStarted
{
	[fullScreenButton setHidden: NO];
	
	[menuSnapshot setEnabled:YES];
}

-(void) displayStopped
{
	[fullScreenButton setHidden: YES];

	[menuSnapshot setEnabled:NO];
}

////////////////////////////////////////////////playback//////////////////////////////////////////////////
-(NSInteger) playPauseState
{
	return [playPauseButton state];
}

-(void) playBackStarted
{
	[dispView setPlayerWindowLevel];
	
	[playPauseButton setState:PlayState];
	
	[speedText setEnabled:YES];
	[subDelayText setEnabled:YES];
	[audioDelayText setEnabled:YES];
}

/** 这个API会在两个时间点被调用，
 * 1. mplayer播放结束，不论是强制结束还是自然结束
 * 2. mplayer播放失败 */
-(void) playBackStopped
{
	[dispView setPlayerWindowLevel];
	
	[playPauseButton setState:PauseState];

	[timeText setStringValue:@""];
	[timeSlider setFloatValue:0];
	
	// 由于mplayer无法静音开始，因此每次都要回到非静音状态
	[volumeButton setState:NSOffState];
	[volumeSlider setEnabled:YES];

	[speedText setEnabled:NO];
	[subDelayText setEnabled:NO];
	[audioDelayText setEnabled:NO];
	
	[menuSwitchSub setEnabled:NO];
	[menuSubScaleInc setEnabled:NO];
	[menuSubScaleDec setEnabled:NO];
	[menuPlayFromLastStoppedPlace setEnabled:NO];
	[menuPlayFromLastStoppedPlace setTag:0];
}

////////////////////////////////////////////////mute/Volume//////////////////////////////////////////////////
-(NSInteger) mute
{
	return [volumeButton state];
}
-(float) volume
{
	return [volumeSlider floatValue];
}
////////////////////////////////////////////////KVO for time//////////////////////////////////////////////////
-(void) gotMediaLength:(NSNumber*) length
{
	if ([length isGreaterThan:[NSNumber numberWithFloat:0]]) {
		[timeSlider setMaxValue:[length doubleValue]];
		[timeSlider setMinValue:0];
	} else {
		[timeSlider setEnabled:NO];
		[hintTime.animator setAlphaValue:0];
	}

}

-(void) gotCurentTime:(NSNumber*) timePos
{
	float time = [timePos floatValue];
	
	[timeText setIntValue:time];
	
	if ([timeSlider isEnabled]) {
		[timeSlider setFloatValue:time];
	}
}

-(void) gotSeekableState:(NSNumber*) seekable
{
	[timeSlider setEnabled:[seekable boolValue]];
}

-(void) gotSpeed:(NSNumber*) speed
{
	[speedText setFloatValue:[speed floatValue]];
}

-(void) gotSubDelay:(NSNumber*) sd
{
	[subDelayText setFloatValue:[sd floatValue]];
}

-(void) gotAudioDelay:(NSNumber*) ad
{
	[audioDelayText setFloatValue:[ad floatValue]];
}

-(void) gotSubInfo:(NSArray*) subs
{
	[subListMenu removeAllItems];
	
	if (subs) {
		unsigned int idx = 0;
		// 将所有的字幕名字加到菜单中
		for(NSString *str in subs) {
			NSMenuItem *mItem = [[NSMenuItem alloc] init];
			[mItem setEnabled:YES];
			[mItem setTarget:self];
			[mItem setAction:@selector(setSubWithID:)];
			[mItem setTitle:str];
			[mItem setTag:idx++];
			[mItem setState:NSOffState];
			[subListMenu addItem:mItem];
			[mItem autorelease];
		}
		// 添加分割线
		NSMenuItem *mItem = [NSMenuItem separatorItem];
		[mItem setEnabled:NO];
		[mItem setTag:-2];
		[mItem setState:NSOffState];
		[subListMenu addItem:mItem];
		
		// 添加 隐藏字幕的菜单选项
		mItem = [[NSMenuItem alloc] init];
		[mItem setEnabled:YES];
		[mItem setTarget:self];
		[mItem setAction:@selector(setSubWithID:)];
		[mItem setTitle:NSLocalizedString(@"Disable", nil)];
		[mItem setTag:-1];
		[mItem setState:NSOffState];
		[subListMenu addItem:mItem];
		[mItem autorelease];
		
		// 选中第一项
		[[subListMenu itemAtIndex:0] setState:NSOnState];
		
		[menuSwitchSub setEnabled:YES];
		[menuSubScaleInc setEnabled:YES];
		[menuSubScaleDec setEnabled:YES];
	} else {
		[menuSwitchSub setEnabled:NO];
		[menuSubScaleInc setEnabled:NO];
		[menuSubScaleDec setEnabled:NO];
	}
}

-(void) gotLastStoppedPlace:(float) tm
{
	[menuPlayFromLastStoppedPlace setTag: ((NSInteger)tm * LASTSTOPPEDTIMERATIO)];
	[menuPlayFromLastStoppedPlace setEnabled: YES];
}

////////////////////////////////////////////////draw myself//////////////////////////////////////////////////
- (void)drawRect:(NSRect)dirtyRect
{
	NSBezierPath* fillPath = [NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:CONTROL_CORNER_RADIUS yRadius:CONTROL_CORNER_RADIUS];
	[fillGradient drawInBezierPath:fillPath angle:270];
}

-(void) mouseMoved:(NSEvent *)theEvent
{
	// 得到鼠标在CotrolUI中的位置
	NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSRect frm = timeSlider.frame;
	
	if (NSPointInRect(pt, frm) && [timeSlider isEnabled]) {
		// 如果鼠标在timeSlider中
		[hintTime setStringValue:[timeFormatter stringForObjectValue:[NSNumber numberWithFloat:((pt.x-frm.origin.x) * [timeSlider maxValue])/ frm.size.width]]];
		
		pt.x -= ([hintTime bounds].size.width /2);
		pt.y = frm.origin.y + frm.size.height + 2;
		[hintTime setFrameOrigin:pt];
		
		[hintTime.animator setAlphaValue:1];
		// [self setNeedsDisplay:YES];
	} else {
		[hintTime.animator setAlphaValue:0];
	}
}

- (void)mouseDragged:(NSEvent *)event
{
	NSRect selfFrame = [self frame];
	NSRect contentBound = [[[self window] contentView] bounds];
	
	selfFrame.origin.x += [event deltaX];
	selfFrame.origin.y -= [event deltaY];
	
	selfFrame.origin.x = MAX(contentBound.origin.x, 
							 MIN(selfFrame.origin.x, contentBound.origin.x + contentBound.size.width - selfFrame.size.width));
	selfFrame.origin.y = MAX(contentBound.origin.y, 
							 MIN(selfFrame.origin.y, contentBound.origin.y + contentBound.size.height - selfFrame.size.height));
	
	[self setFrameOrigin:selfFrame.origin];
}

@end
