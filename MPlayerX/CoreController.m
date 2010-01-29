/*
 * MPlayerX - CoreController.m
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

#import "CoreController.h"
#import <sys/mman.h>
#import "coredef_private.h"

#define kPollingTimeForTimePos	(1)

#define SAFERELEASE(x)			{if(x) {[x release]; x = nil;}}
#define SAFECLOSESHM(x)			{if(x != -1) {close(x); x = -1;}}
#define SAFEUNMAP(x, sz)		{if(x) {munmap(x, sz); x = NULL; sz = 0;}} 
#define SAFERELEASETIMER(x)		{if(x) {[x invalidate]; [x release]; x = nil;}}

// the Distant Protocol from mplayer binary
@protocol MPlayerOSXVOProto
- (int) startWithWidth: (bycopy int)width withHeight: (bycopy int)height withBytes: (bycopy int)bytes withAspect: (bycopy int)aspect;
- (void) stop;
- (void) render;
- (void) toggleFullscreen;
- (void) ontop;
@end

/// 内部方法声明
@interface CoreController (MPlayerOSXVOProto)
- (int) startWithWidth: (bycopy int)width withHeight: (bycopy int)height withBytes: (bycopy int)bytes withAspect: (bycopy int)aspect;
- (void) stop;
- (void) render;
- (void) toggleFullscreen;
- (void) ontop;
@end

@interface CoreController (CoreControllerInternal)
-(void) getCurrentTime:(NSTimer *)theTimer;
@end

@implementation CoreController

@synthesize state;
@synthesize dispDelegate;
@synthesize pm;
@synthesize movieInfo;
@synthesize mpPathPair;
@synthesize la;
@synthesize subConv;

///////////////////////////////////////////Init/Dealloc////////////////////////////////////////////////////////
-(id) init
{
	if (self = [super init]) {
		state = kMPCStoppedState;
		
		pm = [[ParameterManager alloc] init];
		movieInfo = [[MovieInfo alloc] init];

		la = [[LogAnalyzer alloc] initWithDelegate:movieInfo];
		[movieInfo resetWithParameterManager:pm];
		
		playerCore = [[PlayerCore alloc] init];
		[playerCore setDelegate:self];
		mpPathPair = nil;

		imageData = NULL;
		imageSize = 0;
		sharedBufferName = nil;
		shMemID = -1;
		
		dispDelegate = nil;
		
		pollingTimer = nil;
		subConv = [[SubConverter alloc] init];
	}
	return self;
}

-(void) setMpPathPair:(NSDictionary *) dict
{
	if (dict) {
		if ([dict objectForKey:kI386Key] && [dict objectForKey:kX86_64Key]) {
			[dict retain];
			[mpPathPair release];
			mpPathPair = dict;
		}		
	}
	else {
		[mpPathPair release];
		mpPathPair = nil;
	}
}

-(void) dealloc
{
	[movieInfo release];
	[la release];
	[pm release];
	[playerCore release];
	[mpPathPair release];
	[sharedBufferName release];
	SAFERELEASETIMER(pollingTimer);
	[subConv release];

	[super dealloc];
}

//////////////////////////////////////////////Hack to get communicate with mplayer/////////////////////////////////////////////
-(BOOL) conformsToProtocol:(Protocol *)aProtocol
{
	if (aProtocol == @protocol(MPlayerOSXVOProto)) {
		return YES;
	}
	return [super conformsToProtocol: aProtocol];
}

//////////////////////////////////////////////comunication with playerCore/////////////////////////////////////////////////////
-(void) playerCore:(id)player hasTerminated:(BOOL) byForce
{	
	[[NSNotificationCenter defaultCenter] postNotificationName:kMPCPlayWillStopNotification
														object:self
													  userInfo:nil];
	state = kMPCStoppedState;

	SAFERELEASETIMER(pollingTimer);
	[la stop];
	[subConv clearWorkDirectory];

	// 在这里重置textSubs和vobSub，这样在下次播放之前，用户可以自己设置这两个元素
	// !!! 但是要注意，如果是在播放过程中直接调用playMedia函数进行下一个播放的时候
	// !!! 由于playMedia函数会先停止播放，这样会导致sub被清空，在手动选择sub的情况下这里会出现无法手动加载的情况
	// !!! 解决方法是，在CoreController正确先调用performStop在playMedia
	[pm reset];
	
	// 只重置与播放无关的东西
	[movieInfo resetWithParameterManager:nil];
	
	SAFERELEASE(sharedBufferName);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kMPCPlayStoppedNotification 
														object:self
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																[NSNumber numberWithBool:byForce], kMPCPlayStoppedByForceKey,
																[movieInfo.playingInfo currentTime], kMPCPlayStoppedTimeKey, nil]];
	NSLog(@"term:%d", byForce);
}

- (void) playerCore:(id)player outputAvailable:(NSData*)outData
{
	[la analyzeData:outData];
}

- (void) playerCore:(id)player errorHappened:(NSData*) errData
{
	NSString *log = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
	
	NSLog(@"ERR:%@", log);
	[log release];
}

//////////////////////////////////////////////protocol for render/////////////////////////////////////////////////////
- (int) startWithWidth: (bycopy int)width withHeight: (bycopy int)height withBytes: (bycopy int)bytes withAspect: (bycopy int)aspect
{
	// NSLog(@"start");
	if (dispDelegate && sharedBufferName) {
		// 打开shmem
		shMemID = shm_open([sharedBufferName UTF8String], O_RDONLY, S_IRUSR);
		if (shMemID == -1) {
			NSLog(@"shm_open Failed!");
			return 0;
		}
		
		imageSize = width* height* bytes;
		imageData = mmap(NULL, imageSize, PROT_READ, MAP_SHARED, shMemID, 0);
		
		if (imageData == MAP_FAILED) {
			imageData = NULL;
			SAFECLOSESHM(shMemID);
			NSLog(@"mmap Failed");
			return 0;
		}
		return [dispDelegate startWithWidth:width 
									 height:height 
								pixelFormat:((bytes == 4)? k32ARGBPixelFormat: kYUVSPixelFormat) 
									 aspect:aspect
									   from:self];
	}
	return 0;
}

- (void) stop
{
	if (dispDelegate) {
		[dispDelegate stop: self];
		SAFEUNMAP(imageData, imageSize);
		SAFECLOSESHM(shMemID);
	}
}

- (void) render
{
	if (dispDelegate) {
		[dispDelegate draw:imageData from:self];
	}
}

- (void) toggleFullscreen {/* This function should be realized at up-level */}
- (void) ontop {/* This function should be realized at up-level */ }

//////////////////////////////////////////////playing thing/////////////////////////////////////////////////////
-(void) playMedia: (NSString*) moviePath
{
	static unsigned int cnt = 1;

	// 如果正在放映，那么现强制停止
	if (state != kMPCStoppedState) {
		[self performStop];
	}

	// 如果有delegate想要图像数据，那么就建立DistantObject
	if (dispDelegate) {
		sharedBufferName = [[NSString alloc] initWithFormat:@"MPlayerX_%X%d", self, cnt++];
		[[NSConnection serviceConnectionWithName:sharedBufferName rootObject:self] runInNewThread];
	} else {
		// 如果没有人想要图像数据，那么将这个参数设置为nil，会使得mplayer的corevideo放弃生成shmem（ParameterManager里面实现的）
		sharedBufferName = nil;
	}

	// 播放开始之前清空subConv的工作文件夹
	[subConv clearWorkDirectory];
	
	// 如果想要自动获得字幕文件的codepage，需要调用这个函数
	if ([pm guessSubCP]) {
		// 为了支持将来的动态加载字幕，必须先设定字幕为UTF-8，即使没有字幕也要这么设定
		[pm setSubCP:@"UTF-8"];

		NSString *vobStr = nil;
		NSDictionary *subEncDict = [subConv getCPFromMoviePath:moviePath nameRule:pm.subNameRule alsoFindVobSub:&vobStr];
		
		NSString *subStr;
		NSArray *subsArray;
		
		if ([subEncDict count]) {
			// 如果有字幕文件
			subsArray = [subConv convertTextSubsAndEncodings:subEncDict];
			
			if (subsArray && ([subsArray count] > 0)) {
				
				[pm setTextSubs:subsArray];
				if ([pm vobSub] == nil) {
					// 如果用户没有自己设置vobsub的话，这个变量会在每次播放完之后设为nil
					// 如果用户有自己的vobsub，那么就不设置他而用用户的vobsub
					[pm setVobSub:vobStr];
				}
			} else {
				subStr = [[subEncDict allValues] objectAtIndex:0];
				if (![subStr isEqualToString:@""]) {
					// 如果猜出来了
					[pm setSubCP:subStr];
				}
			}
		}
	}

	// 只重置与播放有关的
	[movieInfo.playingInfo resetWithParameterManager:pm];
	
	NSLog(@"%@", [pm arrayOfParametersWithName:sharedBufferName]);
	
	if ( [playerCore playMedia:moviePath 
					  withExec:[mpPathPair objectForKey:(pm.prefer64bMPlayer)?kX86_64Key:kI386Key] 
					withParams:[pm arrayOfParametersWithName:sharedBufferName]]
	   ) {
		state = kMPCPlayingState;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kMPCPlayStartedNotification object:self];
		
		// 这里需要打开Timer去Polling播放时间，然后定期发送现在的播放时间
		pollingTimer = [[NSTimer timerWithTimeInterval:kPollingTimeForTimePos
											    target:self
										 	  selector:@selector(getCurrentTime:)
											  userInfo:nil
											   repeats:YES] retain];

		NSRunLoop *rl = [NSRunLoop currentRunLoop];
		[rl addTimer:pollingTimer forMode:NSDefaultRunLoopMode];
		[rl addTimer:pollingTimer forMode:NSModalPanelRunLoopMode];
		[rl addTimer:pollingTimer forMode:NSEventTrackingRunLoopMode];
	} else {
		// 如果没有成功打开媒体文件
		SAFERELEASE(sharedBufferName);
		[pm reset];
	}
}

-(void) setWorkDirectory:(NSString*) wd
{
	[subConv setWorkDirectory:wd];
}

-(void) getCurrentTime:(NSTimer*)theTimer
{
	if (state == kMPCPlayingState) {
		// 发这个命令会自动让mplayer退出pause状态，而用keep_pause的perfix会得不到任何返回,因此只有在没有pause的时候会polling播放时间
		[playerCore sendStringCommand: [NSString stringWithFormat:@"%@ %@\n", kMPCGetPropertyPreFix, kMPCTimePos]];
	} else if (state == kMPCPausedState) {
		// 即使是暂停的时候这样更新时间，会引发KVO事件，这样是为了保持界面更新
		[movieInfo.playingInfo setCurrentTime:movieInfo.playingInfo.currentTime];
	}
}

-(void) performStop
{
	// 直接停止core，因为self是core的delegate，
	// terminate方法会调用delegate，然后在那里进行相关的清理工作，所以不在这里做
	SAFERELEASETIMER(pollingTimer);
	[playerCore terminate];
}

-(void) togglePause
{
	if (state != kMPCStoppedState) {
		// 如果不是停止状态
		[playerCore sendStringCommand: kMPCTogglePauseCmd];

		if (state == kMPCPlayingState) {
			state = kMPCPausedState;
		} else {
			state = kMPCPlayingState;
		}
	}
}

-(void) setSpeed: (float) speed
{
	speed = MAX(speed, 0.1);
	if ([playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %f\n", kMPCSetPropertyPreFixPauseKeep, kMPCSpeed, speed]]) {
		[movieInfo.playingInfo setSpeed:[NSNumber numberWithFloat: speed]];
	}
}

-(void) setChapter: (int) chapter
{
	if ([playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %d\n", kMPCSetPropertyPreFix, kMPCChapter, chapter]]) {
		[movieInfo.playingInfo setCurrentChapter: chapter];
	}
}

-(float) setTimePos: (float) time
{
	time = MAX(time, 0);
	if ([playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %f\n", kMPCSetPropertyPreFixPauseKeep, kMPCTimePos, time]]) {
		[movieInfo.playingInfo setCurrentTime:[NSNumber numberWithFloat:time]];
		return time;
	}
	return -1;
}

-(float) setVolume: (float) vol
{
	vol = MIN(100, MAX(vol, 0));
	if ([playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %f\n", kMPCSetPropertyPreFixPauseKeep, kMPCVolume, GetRealVolume(vol)]]) {
		[movieInfo.playingInfo setVolume: vol];
	}
	return vol;
}

-(void) setBalance: (float) bal
{
	bal = MIN(1, MAX(bal, -1));
	if ([playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %f\n", kMPCSetPropertyPreFixPauseKeep, kMPCAudioBalance, bal]]) {
		[movieInfo.playingInfo setAudioBalance: bal];
	}
}

-(BOOL) setMute: (BOOL) mute
{
	if ([playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %d\n", kMPCSetPropertyPreFixPauseKeep, kMPCMute, (mute)?1:0]]) {
		[movieInfo.playingInfo setMute:mute];
	} else {
		[movieInfo.playingInfo setMute:NO];
		mute = NO;
	}
	return mute;
}

-(void) setAudioDelay: (float) delay
{
	if ([playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %f\n", kMPCSetPropertyPreFixPauseKeep, kMPCAudioDelay, delay]]) {
		[movieInfo.playingInfo setAudioDelay: [NSNumber numberWithFloat: delay]];
	}
}

-(void) setAudio: (int) audioID
{
	[playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %d\n", kMPCSetPropertyPreFixPauseKeep, kMPCSwitchAudio, audioID]];	
}

-(void) setSub: (int) subID
{
	[playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %d\n", kMPCSetPropertyPreFixPauseKeep, kMPCSub, subID]];
}

-(void) setSubDelay: (float) delay
{
	if ([playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %f\n", kMPCSetPropertyPreFixPauseKeep, kMPCSubDelay, delay]]) {
		[movieInfo.playingInfo setSubDelay:[NSNumber numberWithFloat: delay]];
	}
}

-(void) setSubPos: (float) pos
{
	pos = MIN(100, MAX(pos, 0));
	if ([playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %d\n", kMPCSetPropertyPreFixPauseKeep, kMPCSubPos, ((unsigned int)pos)]]) {
		[movieInfo.playingInfo setSubPos:pos];
	}
}

-(void) setSubScale: (float) scale
{
	scale = MAX(0.1, MIN(scale, 100));

	if ([playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %f\n", kMPCSetPropertyPreFixPauseKeep, kMPCSubScale, scale]]) {
		[movieInfo.playingInfo setSubScale:[NSNumber numberWithFloat:scale]];
	}
}

-(void) loadSubFile: (NSString*) path
{
	NSString *cpStr = [subConv getCPOfTextSubtitle:path];
	if (cpStr) {
		// 找到了编码方式
		NSArray *newPaths = [subConv convertTextSubsAndEncodings:[NSDictionary dictionaryWithObjectsAndKeys:cpStr, path, nil]];
		if (newPaths && [newPaths count]) {
			// NSLog(@"%@", [NSString stringWithFormat:@"%@ \"%@\"", kMPCSubLoad, [newPaths objectAtIndex:0]]);
			[playerCore sendStringCommand:[NSString stringWithFormat:@"%@ \"%@\"\n", kMPCSubLoad, [newPaths objectAtIndex:0]]];
		}
	}
}

-(void) simulateKeyDown: (char) keyCode
{
	[playerCore sendStringCommand: [NSString stringWithFormat:@"%@ %d\n", kMPCKeyEventCmd, keyCode]];
}

@end
