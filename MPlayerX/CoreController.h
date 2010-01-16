/*
 * MPlayerX - CoreController.h
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
#import "PlayerCore.h"
#import "ParameterManager.h"
#import "MovieInfo.h"
#import "LogAnalyzer.h"
#import "SubConverter.h"

// the protocol for displaying the video
@protocol CoreDisplayDelegate
-(int) startWithWidth:(int) width height:(int) height pixelFormat:(OSType) pixelFormat aspect:(int) aspect from:(id)sender;
-(void) draw:(void*)imageData from:(id)sender;
-(void) stop:(id)sender;
@end

#define kMPCPlayStartedNotification		(@"kMPCPlayStartedNotification")
#define kMPCPlayStoppedNotification		(@"kMPCPlayStoppedNotification")
#define kMPCPlayWillStopNotification	(@"kMPCPlayWillStopNotification")

#define kMPCPlayStoppedByForceKey		(@"kMPCPlayStoppedByForceKey")
#define kMPCPlayStoppedTimeKey			(@"kMPCPlayStoppedTimeKey")

#define kMPCStoppedState	(0)		/** 完全停止状态 */
#define kMPCPlayingState	(1)		/** 正在播放并且没有暂停 */
#define kMPCPausedState		(2)		/** 有文件正在播放但是暂停中 */

@class SubConverter;

@interface CoreController : NSObject <PlayerCoreDelegate>
{
	int state;

	MovieInfo *movieInfo;
	LogAnalyzer *la;
	ParameterManager *pm;
	PlayerCore *playerCore;
	NSDictionary *mpPathPair;
	SubConverter *subConv;

	void *imageData;
	unsigned int imageSize;
	NSString *sharedBufferName;
	int shMemID;

	id<CoreDisplayDelegate> dispDelegate;
	
	NSTimer *pollingTimer;
}

@property (readonly)			int state;
@property (retain, readwrite)	NSDictionary *mpPathPair;
@property (readonly)			MovieInfo *movieInfo;
@property (retain, readwrite)	ParameterManager *pm;
@property (readonly)			LogAnalyzer *la;
@property (readonly)			SubConverter *subConv;
@property (assign, readwrite)	id<CoreDisplayDelegate> dispDelegate;

-(void) setWorkDirectory:(NSString*) wd;

-(void) playMedia:(NSString*)moviePath;
-(void) performStop;
-(void) togglePause;

/** 成功发送的话，playingInfo的speed属性会被更新 */
-(void) setSpeed: (float) speed;

/** 成功发送的话，playingInfo的currentChapter属性会被更新 */
-(void) setChapter: (int) chapter;

/** 返回设定的时间值，如果是-1，那说明没有成功发送，但是即使成功发送了，也不会更新playingInfo的currentTime属性，
 *  这个属性会在单独的线程更新，需要用KVO来获取
 */
-(float) setTimePos: (float) time;

/** 成功发送的话，playingInfo的volume属性会被更新,返回能够被更新的正确值 */
-(float) setVolume: (float) vol;

/** 成功发送的话，playingInfo的audioBalance属性会被更新 */
-(void) setBalance: (float) bal;

/** 成功发送的话，playingInfo的mute属性会被更新 */
-(BOOL) setMute: (BOOL) mute;

-(void) setAudioDelay: (float) delay;

-(void) setAudio: (int) audioID;

-(void) setSub: (int) subID;

/** 成功发送的话，playingInfo的subDelay属性会被更新 */
-(void) setSubDelay: (float) delay;

/** 成功发送的话，playingInfo的subPos属性会被更新 */
-(void) setSubPos: (float) pos;

/** 成功发送的话，playingInfo的subScale属性会被更新 */
-(void) setSubScale: (float) scale;

-(void) loadSubFile: (NSString*) path;

-(void) simulateKeyDown: (char) keyCode;
@end

@interface CoreController (PlayerCoreDelegate)
-(void) playerTaskTerminated:(BOOL) byForce from:(id)sender;	/**< 通知播放任务结束 */
-(BOOL) outputAvailable:(NSData*) outData from:(id)sender;		/**< 有输出 */
-(BOOL) errorHappened:(NSData*) errData from:(id)sender;		/**< 有错误输出 */
@end

