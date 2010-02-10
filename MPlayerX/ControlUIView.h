/*
 * MPlayerX - ControlUIView.h
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
#import "TimeFormatter.h"

@class RootLayerView, PlayerController, FloatWrapFormatter, ArrowTextField, ResizeIndicator, OsdText;

@interface ControlUIView : NSView
{
	NSUserDefaults *ud;

	NSGradient *fillGradient;
	
	TimeFormatter *timeFormatter;
	FloatWrapFormatter *floatWrapFormatter;

	NSTimeInterval autoHideTimeInterval;
	BOOL shouldHide;
	NSTimer *autoHideTimer;

	NSDictionary *fillScreenButtonAllImages;
	NSArray *volumeButtonImages;

	NSMenu *subListMenu;

	float volStep;
	BOOL hintTimePrsOnAbs;
	BOOL timeTextPrsOnRmn;

	IBOutlet PlayerController *playerController;
	IBOutlet RootLayerView *dispView;
	IBOutlet NSButton *fillScreenButton;
	IBOutlet NSButton *fullScreenButton;
	IBOutlet NSButton *playPauseButton;
	IBOutlet NSButton *volumeButton;
	IBOutlet NSSlider *volumeSlider;
	IBOutlet NSTextField *timeText;
	IBOutlet NSSlider *timeSlider;
	IBOutlet NSTextField *hintTime;
	
	IBOutlet NSView *accessaryContainer;
	IBOutlet NSButton *toggleAcceButton;

	IBOutlet ArrowTextField *speedText;
	IBOutlet ArrowTextField *subDelayText;
	IBOutlet ArrowTextField *audioDelayText;
	
	IBOutlet ResizeIndicator *rzIndicator;
	IBOutlet OsdText *osd;
	
	IBOutlet NSMenuItem *menuSnapshot;
	IBOutlet NSMenuItem *menuSwitchSub;
	IBOutlet NSMenuItem *menuSubScaleInc;
	IBOutlet NSMenuItem *menuSubScaleDec;
	IBOutlet NSMenuItem *menuPlayFromLastStoppedPlace;
	IBOutlet NSMenuItem *menuSwitchAudio;
	IBOutlet NSMenuItem *menuVolInc;
	IBOutlet NSMenuItem *menuVolDec;
	IBOutlet NSMenuItem *menuToggleLockAspectRatio;
	IBOutlet NSMenuItem *menuResetLockAspectRatio;
	IBOutlet NSMenuItem *menuToggleLetterBox;
}

@property (assign, readwrite) NSTimeInterval autoHideTimeInterval;
@property (assign, readwrite) BOOL hintTimePrsOnAbs;
@property (assign, readwrite) BOOL timeTextPrsOnRmn;

-(IBAction) togglePlayPause:(id)sender;
-(IBAction) toggleMute:(id)sender;

-(IBAction) setVolume:(id)sender;
-(IBAction) changeVolumeBy:(id)sender;

-(IBAction) seekTo:(id) sender;
-(void) changeTimeBy:(float) delta;

-(IBAction) toggleFullScreen:(id)sender;
-(IBAction) toggleFillScreen:(id)sender;

////////////////////////////////显示相关////////////////////////////////
#define kFillScreenButtonImageLRKey		(@"LR")
#define kFillScreenButtonImageUBKey		(@"UB")
-(void) setFillScreenMode:(NSString*)modeKey state:(NSInteger) state;

-(void) displayStarted;
-(void) displayStopped;

////////////////////////////////播放相关////////////////////////////////
-(void) playBackStarted;
-(void) playBackStopped;
-(void) playBackWillStop;

////////////////////////////////KVO相关////////////////////////////////
-(void) gotMediaLength:(NSNumber*) length;
-(void) gotCurentTime:(NSNumber*) timePos;
-(void) gotSeekableState:(NSNumber*) seekable;
-(void) gotSpeed:(NSNumber*) speed;
-(void) gotSubDelay:(NSNumber*) sd;
-(void) gotAudioDelay:(NSNumber*) ad;
-(void) gotSubInfo:(NSArray*) subs;
-(void) gotLastStoppedPlace:(float) tm;
-(void) gotNewSubs:(NSArray*) newSubs;
-(void) gotCachingPercent:(NSNumber*) caching;

//////////////////////////////自动隐藏相关/////////////////////////////
-(void) showUp;
-(void) updateHintTime;
-(void) doHide;
-(void) refreshBackgroundAlpha;
-(void) refreshAutoHideTimer;
-(void) refreshOSDSetting;

//////////////////////////////其他控件相关/////////////////////////////
-(IBAction) toggleAccessaryControls:(id)sender;
-(IBAction) changeSpeed:(id) sender;
-(IBAction) changeAudioDelay:(id) sender;
-(IBAction) changeSubDelay:(id)sender;

-(IBAction) stepSubtitles:(id)sender;
-(IBAction) setSubWithID:(id)sender;

-(IBAction) changeSubScale:(id)sender;
-(IBAction) playFromLastStopped:(id)sender;

-(IBAction) stepAudios:(id)sender;

-(IBAction) toggleTimeTextDispMode:(id)sender;
-(IBAction) changeSubPosBy:(id)sender;
-(IBAction) changeAudioBalanceBy:(id)sender;

-(IBAction) toggleLockAspectRatio:(id)sender;
-(IBAction) resetAspectRatio:(id)sender;

-(IBAction) toggleLetterBox:(id)sender;
@end
