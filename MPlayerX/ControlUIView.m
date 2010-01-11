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

#define PlayState	(NSOnState)
#define PauseState	(NSOffState)

@interface ControlUIView (ControlUIViewInternal)
- (void) windowHasResized:(NSNotification *)notification;
-(void) calculateHintTime;
@end


@implementation ControlUIView

@synthesize autoHideTimeInterval;
@synthesize hintTimePrsOnAbs;
@synthesize timeTextPrsOnRmn;

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithFloat:100], kUDKeyVolume,
					   [NSNumber numberWithDouble:AUTOHIDETIMEINTERNAL], kUDKeyCtrlUIAutoHideTime,
					   [NSNumber numberWithBool:NO], kUDKeySwitchTimeHintPressOnAbusolute,
					   [NSNumber numberWithFloat:10], kUDKeyVolumeStep,
					   [NSNumber numberWithBool:YES], kUDKeySwitchTimeTextPressOnRemain,
					   nil]];
}

-(void) loadButtonImages
{
	// 初始化音量大小图标
	volumeButtonImages = [[NSArray alloc] initWithObjects:	[NSImage imageNamed:@"vol_no"], [NSImage imageNamed:@"vol_low"],
															[NSImage imageNamed:@"vol_mid"], [NSImage imageNamed:@"vol_high"],
															nil];
	// fillScreenButton初期化
	fillScreenButtonAllImages =  [[NSDictionary alloc] initWithObjectsAndKeys: 
								  [NSArray arrayWithObjects:[NSImage imageNamed:@"fillscreen_lr"], [NSImage imageNamed:@"exitfillscreen_lr"], nil], kFillScreenButtonImageLRKey,
								  [NSArray arrayWithObjects:[NSImage imageNamed:@"fillscreen_ub"], [NSImage imageNamed:@"exitfillscreen_ub"], nil], kFillScreenButtonImageUBKey, 
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
	[menuSwitchSub setKeyEquivalent:kSCMSwitchSubKeyEquivalent];
	
	[menuSubScaleInc setKeyEquivalentModifierMask:kSCMSubScaleIncreaseKeyEquivalentModifierFlagMask];
	[menuSubScaleInc setKeyEquivalent:kSCMSubScaleIncreaseKeyEquivalent];
	[menuSubScaleDec setKeyEquivalentModifierMask:kSCMSubScaleDecreaseKeyEquivalentModifierFlagMask];
	[menuSubScaleDec setKeyEquivalent:kSCMSubScaleDecreaseKeyEquivalent];
	
	[menuPlayFromLastStoppedPlace setKeyEquivalent:kSCMPlayFromLastStoppedKeyEquivalent];
	[menuPlayFromLastStoppedPlace setKeyEquivalentModifierMask:kSCMPlayFromLastStoppedKeyEquivalentModifierFlagMask];
	
	[menuSwitchAudio setKeyEquivalent:kSCMSwitchAudioKeyEquivalent];

	[menuVolInc setKeyEquivalent:kSCMVolumeUpKeyEquivalent];
	[menuVolDec setKeyEquivalent:kSCMVolumeDownKeyEquivalent];
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

	[menuVolInc setEnabled:YES];
	[menuVolInc setTag:1];
	
	[menuVolDec setEnabled:YES];
	[menuVolDec setTag:-1];

	volStep = [[NSUserDefaults standardUserDefaults] floatForKey:kUDKeyVolumeStep];

	// 初始化时间显示slider和text
	timeFormatter = [[TimeFormatter alloc] init];
	[[timeText cell] setFormatter:timeFormatter];
	[timeText setStringValue:@""];
	[timeSlider setEnabled:NO];
	[timeSlider setMaxValue:-1];
	[timeSlider setMinValue:-2];

	[hintTime setAlphaValue:0];
	[[hintTime cell] setFormatter:timeFormatter];
	[hintTime setStringValue:@""];

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
	
	hintTimePrsOnAbs = [[NSUserDefaults standardUserDefaults] boolForKey:kUDKeySwitchTimeHintPressOnAbusolute];
	timeTextPrsOnRmn = [[NSUserDefaults standardUserDefaults] boolForKey:kUDKeySwitchTimeTextPressOnRemain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowHasResized:)
												 name:NSWindowDidResizeNotification
											   object:[self window]];
}

-(void) dealloc
{
	[autoHideTimer invalidate];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];

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
				if ([dispView isInFullScreenMode]) {
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

	if ([dispView isInFullScreenMode]) {
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
	[appController togglePlayPause];
	
	if (appController.playerState == kMPCStoppedState) {
		// 如果失败的话，ControlUI回到停止状态
		[self playBackStopped];
	} else {
		[dispView setPlayerWindowLevel];
	}
}

-(IBAction) toggleMute:(id)sender
{
	BOOL mute = [appController toggleMute];

	[volumeButton setState:(mute)?NSOnState:NSOffState];
	[volumeSlider setEnabled:!mute];
	[menuVolInc setEnabled:!mute];
	[menuVolDec setEnabled:!mute];
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

-(IBAction) changeVolumeBy:(id)sender
{
	[self setVolume:[NSNumber numberWithFloat:[volumeSlider floatValue] + ([sender tag] * volStep)]];
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
	if ([dispView toggleFullScreen]) {
		// 成功
		if ([dispView isInFullScreenMode]) {
			// 进入全屏
			
			[fullScreenButton setState: NSOnState];

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
			CGDisplayShowCursor(dispView.fullScrnDevID);

			[fullScreenButton setState: NSOffState];

			[fillScreenButton setHidden: YES];
			
			if ([self alphaValue] > (BACKGROUND_ALPHA-0.05)) {
				// 如果controlUI没有隐藏，那么显示resizeindiccator
				[rzIndicator.animator setAlphaValue:1];
			}
		}
	} else {
		// 失败
		[fullScreenButton setState: NSOffState];
		[fillScreenButton setHidden: YES];
	}
	[hintTime.animator setAlphaValue:0];
}

-(IBAction) toggleFillScreen:(id)sender
{
	[fillScreenButton setState: ([dispView toggleFillScreen])?NSOnState:NSOffState];
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

	[hintTime.animator setAlphaValue:0];
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

/** \warning this is a temporary implementation */
-(IBAction) stepAudios:(id)sender
{
	[appController setAudio:-1];
	// 这个可能是mplayer的bug，当轮转一圈从各个音轨到无声在回到音轨时，声音会变到最大，所以这里再设定一次音量
	[self setVolume:volumeSlider];
}

-(IBAction) toggleTimeTextDispMode:(id)sender
{
	timeTextPrsOnRmn = !timeTextPrsOnRmn;
}

////////////////////////////////////////////////FullscreenThings//////////////////////////////////////////////////
-(void) setFillScreenMode:(NSString*)modeKey state:(NSInteger) state
{
	NSArray *fillScrnBtnModeImages = [fillScreenButtonAllImages objectForKey:modeKey];
	
	if (fillScrnBtnModeImages) {
		[fillScreenButton setImage:[fillScrnBtnModeImages objectAtIndex:0]];
		[fillScreenButton setAlternateImage:[fillScrnBtnModeImages objectAtIndex:1]];
	}	
	[fillScreenButton setState:state];
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
-(void) playBackStarted
{
	[dispView setPlayerWindowLevel];
	
	[playPauseButton setState:PlayState];
	
	[speedText setEnabled:YES];
	[subDelayText setEnabled:YES];
	[audioDelayText setEnabled:YES];
	
	[menuSwitchAudio setEnabled:YES];
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
	[menuVolInc setEnabled:YES];
	[menuVolDec setEnabled:YES];

	[speedText setEnabled:NO];
	[subDelayText setEnabled:NO];
	[audioDelayText setEnabled:NO];
	
	[menuSwitchAudio setEnabled:NO];
	[menuSwitchSub setEnabled:NO];
	[menuSubScaleInc setEnabled:NO];
	[menuSubScaleDec setEnabled:NO];
	[menuPlayFromLastStoppedPlace setEnabled:NO];
	[menuPlayFromLastStoppedPlace setTag:0];
	
	timeTextPrsOnRmn = [[NSUserDefaults standardUserDefaults] boolForKey:kUDKeySwitchTimeTextPressOnRemain];
}

////////////////////////////////////////////////KVO for time//////////////////////////////////////////////////
-(void) gotMediaLength:(NSNumber*) length
{
	if ([length isGreaterThan:[NSNumber numberWithFloat:0]]) {
		[timeSlider setMaxValue:[length doubleValue]];
		[timeSlider setMinValue:0];
	} else {
		[timeSlider setEnabled:NO];
		[timeSlider setMaxValue:-1];
		[timeSlider setMinValue:-2];
		[hintTime.animator setAlphaValue:0];
	}
}

-(void) gotCurentTime:(NSNumber*) timePos
{
	float time = [timePos floatValue];
	
	if (([timeSlider maxValue] > 0) && 
		((([NSEvent modifierFlags]&NSCommandKeyMask)?YES:NO) == timeTextPrsOnRmn)) {
		// 如果有时间的长度，并且按键和设定相符合的时候，显示remain时间
		[timeText setIntValue:time - [timeSlider maxValue] - 0.5];
		
	} else {
		// 没有得到电影的长度，只显示现在的时间
		[timeText setIntValue:time + 0.5];
	}
	
	// 即使timeSlider被禁用也可以显示时间
	[timeSlider setFloatValue:time];
	
	if ([timeSlider isEnabled]) {
		[self calculateHintTime];
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

-(void) calculateHintTime
{
	NSPoint pt = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
	NSRect frm = timeSlider.frame;
	
	float timeDisp = ((pt.x-frm.origin.x) * [timeSlider maxValue])/ frm.size.width;;

	if ((([NSEvent modifierFlags] & kSCMSwitchTimeHintKeyModifierMask)?YES:NO) != hintTimePrsOnAbs) {
		// 如果没有按cmd，显示时间差
		// 否则显示绝对时间
		timeDisp -= [timeSlider floatValue];
	}
	[hintTime setIntValue:timeDisp + ((timeDisp>0)?0.5:-0.5)];
}

-(void) updateHintTime
{
	// 得到鼠标在CotrolUI中的位置
	NSPoint pt = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
	NSRect frm = timeSlider.frame;

	if (NSPointInRect(pt, frm) && [timeSlider isEnabled]) {
		// 如果鼠标在timeSlider中
		// 更新时间
		[self calculateHintTime];
		
		CGFloat wd = [hintTime bounds].size.width;
		pt.x -= (wd/2);
		pt.x = MIN(pt.x, [self bounds].size.width - wd);
		pt.y = frm.origin.y + frm.size.height - 1;
		
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

-(void) windowHasResized:(NSNotification *)notification
{
	[hintTime.animator setAlphaValue:0];
	
	NSRect frm = self.frame;
	NSRect contBounds = [self superview].bounds;
	
	frm.origin.y = MIN(frm.origin.y, contBounds.size.height-frm.size.height);
	[self setFrame:frm];
}
@end
