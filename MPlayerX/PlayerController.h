/*
 * MPlayerX - PlayerController.h
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
#import "CoreController.h"

@class ControlUIView;

@interface PlayerController : NSObject <NSApplicationDelegate>
{
	NSUserDefaults *ud;

	CoreController *mplayer;
	NSString *lastPlayedPath;
	NSString *lastPlayedPathPre;
	NSSet *supportVideoFormats;
	NSSet *supportAudioFormats;
	NSMutableDictionary *bookmarks;
	
	IBOutlet NSWindow *window;
	IBOutlet ControlUIView *controlUI;
	IBOutlet NSTextField *aboutText;
}

@property (readonly) NSString *lastPlayedPath;

-(void) setDelegateForMPlayer:(id<CoreDisplayDelegate>) delegate;
-(int) playerState;

-(void) setMultiThreadMode:(BOOL) mt;

-(BOOL) playMedia:(NSURL*)url;

-(void) togglePlayPause;	/** 返回PlayPause是否成功 */
-(BOOL) toggleMute;			/** 返回现在的mute状态 */
-(float) setVolume:(float) vol;	/** 返回现在的音量 */
-(float) seekTo:(float) time;	/** 返回现在要去的时间 */

-(float) changeTimeBy:(float) delta;  /** 返回现在的时间值 */
-(float) changeSpeedBy:(float) delta; /** 返回现在的速度值 */

-(float) changeSubDelayBy:(float) delta;
-(float) changeAudioDelayBy:(float) delta;
-(float) changeSubScaleBy:(float) delta;
-(float) changeSubPosBy:(float)delta;
-(float) changeAudioBalanceBy:(float)delta;

-(float) setSpeed:(float) spd;
-(float) setSubDelay:(float) sd;
-(float) setAudioDelay:(float) ad;
-(void) setSubtitle:(int) subID;
-(void) setAudio:(int) audioID;
-(void) setAudioBalance:(float)bal;

-(void) loadSubFile:(NSString*)subPath;

-(IBAction) openFile:(id) sender;
-(IBAction) showHelp:(id) sender;

@end
