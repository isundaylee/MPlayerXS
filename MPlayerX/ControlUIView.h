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
#import "TimeSlider.h"

@class RootLayerView, AppController, FloatWrapFormatter, ArrowTextField;

@interface ControlUIView : NSView
{
	TimeFormatter *timeFormatter;
	FloatWrapFormatter *floatWrapFormatter;

	NSTimeInterval autoHideTimeInterval;
	BOOL shouldHide;
	NSTimer *autoHideTimer;

	NSDictionary *fillScreenButtonAllImages;
	NSArray *volumeButtonImages;
	NSImage *imVolNo;
	NSImage *imVolLow;
	NSImage *imVolMid;
	NSImage *imVolHigh;
	NSImage *imFillScrnInLR;
	NSImage *imFillScrnOutLR;
	NSImage *imFillScrnInUB;
	NSImage *imFillScrnOutUB;

	NSMenu *subListMenu;

	IBOutlet AppController *appController;
	IBOutlet RootLayerView *dispView;
	IBOutlet NSButton *fillScreenButton;
	IBOutlet NSButton *fullScreenButton;
	IBOutlet NSButton *playPauseButton;
	IBOutlet NSButton *volumeButton;
	IBOutlet NSSlider *volumeSlider;
	IBOutlet NSTextField *timeText;
	IBOutlet TimeSlider *timeSlider;
	
	IBOutlet NSView *accessaryContainer;
	IBOutlet NSButton *toggleAcceButton;

	IBOutlet ArrowTextField *speedText;
	IBOutlet ArrowTextField *subDelayText;
	IBOutlet ArrowTextField *audioDelayText;
	
	IBOutlet NSMenuItem *menuSnapshot;
	IBOutlet NSMenuItem *menuSwitchSub;
	IBOutlet NSMenuItem *menuSubScaleInc;
	IBOutlet NSMenuItem *menuSubScaleDec;
	IBOutlet NSMenuItem *menuPlayFromLastStoppedPlace;
}

@property (assign, readwrite) NSTimeInterval autoHideTimeInterval;

-(IBAction) togglePlayPause:(id)sender;
-(IBAction) toggleMute:(id)sender;
-(IBAction) setVolume:(id)sender;
-(IBAction) seekTo:(id) sender;

-(IBAction) toggleFullScreen:(id)sender;
-(IBAction) toggleFillScreen:(id)sender;

////////////////////////////////显示相关////////////////////////////////
-(NSInteger) isFullScreen;
-(NSInteger) isFillScreen;

#define kFillScreenButtonImageLRKey		(@"LR")
#define kFillScreenButtonImageUBKey		(@"UB")
-(void) setFillScreenMode:(NSString*)modeKey state:(NSInteger) state;

-(void) exitedFullScreen;

-(void) displayStarted;
-(void) displayStopped;

////////////////////////////////播放相关////////////////////////////////
#define PlayState	(NSOnState)
#define PauseState	(NSOffState)
-(NSInteger) playPauseState;
-(void) playBackStarted;
-(void) playBackStopped;

////////////////////////////////音量相关////////////////////////////////
-(NSInteger) mute;
-(float) volume;

////////////////////////////////KVO相关////////////////////////////////
-(void) gotMediaLength:(NSNumber*) length;
-(void) gotCurentTime:(NSNumber*) timePos;
-(void) gotSeekableState:(NSNumber*) seekable;
-(void) gotSpeed:(NSNumber*) speed;
-(void) gotSubDelay:(NSNumber*) sd;
-(void) gotAudioDelay:(NSNumber*) ad;
-(void) gotSubInfo:(NSArray*) subs;
-(void) gotLastStoppedPlace:(float) tm;

//////////////////////////////自动隐藏相关/////////////////////////////
-(void) showUp;

//////////////////////////////其他控件相关/////////////////////////////
-(IBAction) toggleAccessaryControls:(id)sender;
-(void) hideAccessaryControls;

-(IBAction) changeSpeed:(id) sender;
-(IBAction) changeAudioDelay:(id) sender;
-(IBAction) changeSubDelay:(id)sender;
-(IBAction) stepSubtitles:(id)sender;
-(IBAction) setSubWithID:(id)sender;
-(IBAction) changeSubScale:(id)sender;
-(IBAction) playFromLastStopped:(id)sender;

@end
