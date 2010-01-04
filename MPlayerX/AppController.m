/*
 * MPlayerX - AppController.m
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
#import "AppController.h"
#import "MPlayerController.h"
#import "RootLayerView.h"
#import "ControlUIView.h"
#import "PlayList.h"
#import <sys/sysctl.h>
#import <Sparkle/Sparkle.h>

#define kObservedValueStringMediaLength		(@"movieInfo.length")
#define kObservedValueStringCurrentTime		(@"movieInfo.playingInfo.currentTime")
#define kObservedValueStringSeekable		(@"movieInfo.seekable")
#define kObservedValueStringSpeed			(@"movieInfo.playingInfo.speed")
#define kObservedValueStringSubDelay		(@"movieInfo.playingInfo.subDelay")
#define kObservedValueStringAudioDelay		(@"movieInfo.playingInfo.audioDelay")
#define kObservedValueStringSubInfo			(@"movieInfo.subInfo")

#define kMPCDefaultSubFontPath				(@"/wqy-microhei.ttc")

@interface AppController (MPlayerControllerNotification)
-(void) mplayerStarted:(NSNotification *)notification;
-(void) mplayerStopped:(NSNotification *)notification;
-(void) preventSystemSleep;
-(void) tryToPlayNext;
@end

@implementation AppController

@synthesize mplayer;
@synthesize lastPlayedPath;

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithBool:YES], kUDKeyAutoPlayNext,
					   kMPCDefaultSubFontPath, kUDKeySubFontPath,
					   [NSNumber numberWithBool:YES], kUDKeyPrefer64bitMPlayer,
					   [NSNumber numberWithBool:NO], kUDKeyEnableMultiThread,
					   [NSNumber numberWithFloat:4], kUDKeySubScale,
					   [NSNumber numberWithFloat:0.1], kUDKeySubScaleStepValue,
					   @"http://mplayerx.googlecode.com/svn/trunk/update/appcast.xml", @"SUFeedURL",
					   [NSDictionary dictionary], kUDKeyPlayingTimeDic, 
					   nil]];
}

#pragma mark Init/Dealloc
-(id) init
{
	if (self = [super init]) {
		mplayer = [[MPlayerController alloc] init];
		lastPlayedPath = nil;
		lastPlayedPathPre = nil;
	}
	return self;
}

-(BOOL) shouldRun64bitMPlayer
{
	int value = 0 ;
	unsigned long length = sizeof(value);
	
	if ((sysctlbyname("hw.optional.x86_64", &value, &length, NULL, 0) == 0) && (value == 1))
		return [[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyPrefer64bitMPlayer];
	
	return NO;
}

-(void) awakeFromNib
{
	[aboutText setStringValue:[NSString stringWithFormat: @"MPlayerX %@ by Niltsh@2009\nhttp://code.google.com/p/mplayerx/\nzongyao.qu@gmail.com\n\nThanks to\n\nmplayer\nhttp://www.mplayerhq.hu\n\nUniversalDetector\nhttp://wakaba.c3.cx/s/apps/unarchiver.html\n\nBGHUDAppKit\nhttp://www.binarymethod.com/bghudappkit/\n\nWenQuan MicroHei Font\nhttp://www.wenq.org", 
															[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]]];
	

	// 初始化MPlayerController
	NSString *resPath = [[NSBundle mainBundle] resourcePath];
	
	[self setMultiThreadMode:[[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyEnableMultiThread]];
	
	// 得到字幕字体文件的路径
	NSString *subFontPath = [[NSUserDefaults standardUserDefaults] stringForKey:kUDKeySubFontPath];
	
	if ([subFontPath isEqualToString:kMPCDefaultSubFontPath]) {
		// 如果是默认的路径的话，需要添加一些路径头
		[mplayer.pm setSubFont:[resPath stringByAppendingString:subFontPath]];
	} else {
		// 否则直接设定
		[mplayer.pm setSubFont:subFontPath];
	}
	
	// 决定是否使用64bit的mplayer
	[mplayer.pm setPrefer64bMPlayer:[self shouldRun64bitMPlayer]];

	// 设定字幕大小
	[mplayer.pm setSubScale:[[NSUserDefaults standardUserDefaults] floatForKey:kUDKeySubScale]];
	
	// 通知dispView接受mplayer的渲染通知
	[mplayer setDispDelegate:dispView];
	
	// 开始监听mplayer的开始/结束事件
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mplayerStarted:)
												 name:kMPCPlayStartedNotification
											   object:mplayer];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mplayerStopped:)
												 name:kMPCPlayStoppedNotification
											   object:mplayer];
	// 设置监听KVO
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringMediaLength
				 options:NSKeyValueObservingOptionNew
				 context:NULL];
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringCurrentTime
				 options:NSKeyValueObservingOptionNew
				 context:NULL];
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringSeekable
				 options:NSKeyValueObservingOptionNew
				 context:NULL];
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringSpeed
				 options:NSKeyValueObservingOptionNew
				 context:NULL];
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringSubDelay
				 options:NSKeyValueObservingOptionNew
				 context:NULL];
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringAudioDelay
				 options:NSKeyValueObservingOptionNew
				 context:NULL];
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringSubInfo
				 options:NSKeyValueObservingOptionNew
				 context:NULL];

	// 建立支持格式的Set
	supportMediaFormats = [[NSMutableSet alloc] initWithCapacity:80];
	for( NSDictionary *dict in [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDocumentTypes"]) {
		[supportMediaFormats addObjectsFromArray:[dict objectForKey:@"CFBundleTypeExtensions"]];
	}
	
	[[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:NO];
}

-(void) dealloc
{
	// 结束监听mplayer的开始/结束事件
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	// 结束监听KVO
	[mplayer removeObserver:self forKeyPath:kObservedValueStringCurrentTime];
	[mplayer removeObserver:self forKeyPath:kObservedValueStringMediaLength];
	[mplayer removeObserver:self forKeyPath:kObservedValueStringSeekable];
	[mplayer removeObserver:self forKeyPath:kObservedValueStringSpeed];
	[mplayer removeObserver:self forKeyPath:kObservedValueStringSubDelay];
	[mplayer removeObserver:self forKeyPath:kObservedValueStringAudioDelay];
	[mplayer removeObserver:self forKeyPath:kObservedValueStringSubInfo];
	
	[mplayer release];
	[supportMediaFormats release];
	[super dealloc];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == mplayer) {
		if ([keyPath isEqualToString:kObservedValueStringCurrentTime]) {
			// 得到现在的播放时间
			[controlUI gotCurentTime:[change objectForKey:NSKeyValueChangeNewKey]];
			
		} else if ([keyPath isEqualToString:kObservedValueStringSpeed]) {
			// 得到播放速度
			[controlUI gotSpeed:[change objectForKey:NSKeyValueChangeNewKey]];
			
		} else if ([keyPath isEqualToString:kObservedValueStringSubDelay]) {
			// 得到 字幕延迟
			[controlUI gotSubDelay:[change objectForKey:NSKeyValueChangeNewKey]];
			
		} else if ([keyPath isEqualToString:kObservedValueStringAudioDelay]) {
			// 得到 声音延迟
			[controlUI gotAudioDelay:[change objectForKey:NSKeyValueChangeNewKey]];
			
		} else if ([keyPath isEqualToString:kObservedValueStringMediaLength]){
			// 得到媒体文件的长度
			[controlUI gotMediaLength:[change objectForKey:NSKeyValueChangeNewKey]];
			
		} else if ([keyPath isEqualToString:kObservedValueStringSeekable]) {
			// 得到 能否跳跃
			[controlUI gotSeekableState:[change objectForKey:NSKeyValueChangeNewKey]];
			
		} else if ([keyPath isEqualToString:kObservedValueStringSubInfo]) {
			// 得到 字幕信息
			[controlUI gotSubInfo:[change objectForKey:NSKeyValueChangeNewKey]];
		}
		return;
	}
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(void) preventSystemSleep
{
	if (mplayer.isPlaying &&(!mplayer.isPaused)) {
		UpdateSystemActivity(OverallAct);
		[self performSelector:@selector(preventSystemSleep) withObject:nil afterDelay:20];
	}
}

-(BOOL) playMedia:(NSURL*)url
{
	BOOL ret = NO;
	if (url != nil) {
		NSString *path;
		
		if ([url isFileURL]) {
			// 如果是本地文件
			path = [url path];
			// 进行格式验证
			if ([supportMediaFormats containsObject:[path pathExtension]]) {
				BOOL isDir = YES;
				if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && (!isDir)) {
					// 为了保险期间，每次播放开始的时候
					// 将播放开始时间重置
					[mplayer.pm setStartTime:-1];
					
					lastPlayedPathPre = [NSString stringWithString:path];
					[mplayer playMedia:lastPlayedPathPre];
					// 通过的话就播放
					lastPlayedPath = lastPlayedPathPre;
					lastPlayedPathPre = nil;
					
					ret = YES;
				}
			} else {
				// 否则提示
				if ([window isVisible]) {
					NSBeginAlertSheet(NSLocalizedString(@"Error", nil), NSLocalizedString(@"OK", nil), nil, nil, window, nil, nil, nil, nil, NSLocalizedString(@"The File is unsupported by MPlayerX.", nil));
				} else {
					id alertPanel = NSGetAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"The File is unsupported by MPlayerX.", nil), NSLocalizedString(@"OK", nil), nil, nil);
					[NSApp runModalForWindow:alertPanel];
					NSReleaseAlertPanel(alertPanel);
				}
			}
		} else {
			// 非本地文件
			path = [[url standardizedURL] absoluteString];
			
			[mplayer.pm setStartTime:-1];
			
			lastPlayedPathPre = [NSString stringWithString:path];
			[mplayer playMedia:path];
			lastPlayedPath = lastPlayedPathPre;
			lastPlayedPathPre = nil;
			ret = YES;
		}
	}
	return ret;
}

-(void) setMultiThreadMode:(BOOL) mt
{
	NSString *resPath = [[NSBundle mainBundle] resourcePath];
	
	NSString *mplayerName;
	unsigned int threadNum;
	
	if (mt) {
		// 使用多线程
		threadNum = MAX(2,[[NSProcessInfo processInfo] processorCount]);
		mplayerName = @"mplayer-mt";		
	} else {
		threadNum = 1;
		mplayerName = @"mplayer";
	}
	
	[mplayer.pm setThreads: threadNum];
	
	[mplayer setMpPathPair: [NSDictionary dictionaryWithObjectsAndKeys: 
							 [resPath stringByAppendingString:[NSString stringWithFormat:@"/binaries/m32/%@", mplayerName]], kI386Key,
							 [resPath stringByAppendingString:[NSString stringWithFormat:@"/binaries/x86_64/%@", mplayerName]], kX86_64Key,
							 nil]];		
	
}
///////////////////////////////////////MPlayer Notifications/////////////////////////////////////////////
-(void) mplayerStarted:(NSNotification *)notification
{
	[window setTitle:[lastPlayedPathPre lastPathComponent]];
	[dispView setPlayerWindowLevel];
	[controlUI playBackStarted];
	[self preventSystemSleep];
	
	// 用文件名查找有没有之前的播放记录
	NSNumber *stopTime = [[[NSUserDefaults standardUserDefaults] objectForKey:kUDKeyPlayingTimeDic] objectForKey:lastPlayedPathPre];
	NSLog(@"Pre:%@", lastPlayedPathPre);
	if (stopTime) {
		// 有的话，通知controlUI
		[controlUI gotLastStoppedPlace:[stopTime floatValue]];
	}
}

-(void) mplayerStopped:(NSNotification *)notification
{
	[window setTitle: @"MPlayerX"];
	[dispView setPlayerWindowLevel];
	[controlUI playBackStopped];
	
	// 得到文件播放时刻的Dict
	NSMutableDictionary *ptDic = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey: kUDKeyPlayingTimeDic]];
	
	if ([[[notification userInfo] objectForKey:kMPCPlayStoppedByForceKey] boolValue]) {
		// 如果是强制停止
		// 用文件名做key，记录这个文件的播放时间
		[ptDic setObject:[[notification userInfo] objectForKey:kMPCPlayStoppedTimeKey] forKey:lastPlayedPath];
	} else {
		// 自然关闭
		// 删除这个文件key的播放时间
		[ptDic removeObjectForKey:lastPlayedPath];
	}
	NSLog(@"StopPath:%@", lastPlayedPath);
	[[NSUserDefaults standardUserDefaults] setObject:ptDic forKey:kUDKeyPlayingTimeDic];
	//[[NSUserDefaults standardUserDefaults] synchronize];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyAutoPlayNext] && 
		(![[[notification userInfo] objectForKey:kMPCPlayStoppedByForceKey] boolValue])
	   ) {
		//如果不是强制关闭的话
		//如果不是本地文件，肯定返回nil
		NSString *nextPath = [PlayList AutoSearchNextMoviePathFrom:lastPlayedPath];
		if (nextPath != nil) { 
			// 如果没有下一个文件，那么就不要浪费一个Timer了
			
			// 这个时间的设定是一个trick，如果直接调用会造成线程锁死，因为再delegate方法里面设定了waituntildone为Yes
			// 因此用了Timer，但是在这个时间期间用户选择别的文件播放或者mplayer还没有回到正常的等待状态
			// 那么就应该放弃下一个文件
			[self performSelector:@selector(tryToPlayNext) 
					   withObject:nil 
					   afterDelay:0.5
						  inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode,NSEventTrackingRunLoopMode,nil]];
		}
	}
}

-(void) tryToPlayNext
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyAutoPlayNext] && 
		(!mplayer.isPlaying)
	   ) {
		//如果不是本地文件，肯定返回nil
		NSString *nextPath = [PlayList AutoSearchNextMoviePathFrom:lastPlayedPath];
		if (nextPath != nil) {
			[self playMedia:[NSURL fileURLWithPath:nextPath isDirectory:NO]];
		}
	}
}

////////////////////////////////////////////////cooperative actions with UI//////////////////////////////////////////////////
-(BOOL) togglePlayPause
{
	BOOL ret = YES;
	if (mplayer.isPlaying) {
		// mplayer正在播放
		if ([controlUI playPauseState] == PauseState) {
			// 想暂停
			if (!mplayer.isPaused) {
				[mplayer togglePause];
				[dispView setPlayerWindowLevel];
			}
		} else {
			// 想播放
			if (mplayer.isPaused) {
				[mplayer togglePause];
				[dispView setPlayerWindowLevel];
			}
		}
	} else {
		//mplayer不在播放状态
		if ([controlUI playPauseState] == PauseState) {
			// 想暂停
		} else {
			// 想播放
			if (lastPlayedPath) {
				// 有可以播放的文件
				ret = [self playMedia:[NSURL fileURLWithPath:lastPlayedPath isDirectory:NO]];
			} else {
				// 没有可以播放的文件
				ret = NO;
			}
		}
	}
	return ret;
}

-(BOOL) toggleMute
{
	return (mplayer.isPlaying)? ([mplayer setMute:((controlUI.mute == NSOnState)?YES:NO)]):NO;
}

-(float) setVolume:(float) vol
{
	vol = [mplayer setVolume:vol];
	[mplayer.pm setVolume:vol];
	return vol;
}

-(float) seekTo:(float) time
{
	// playingInfo的currentTime是通过获取log来同步的，因此这里不进行直接设定
	if (mplayer.isPlaying) {
		time = [mplayer setTimePos:time];
		[mplayer.la stop];
		return time;
	}
	return -1;
}

-(float) changeTimeBy:(float) delta
{
	// playingInfo的currentTime是通过获取log来同步的，因此这里不进行直接设定
	if (mplayer.isPlaying) {
		delta = [mplayer setTimePos:[mplayer.movieInfo.playingInfo.currentTime floatValue] + delta];	
		[mplayer.la stop];
		return delta;
	}
	return -1;
}

-(float) changeSpeedBy:(float) delta
{
	if (mplayer.isPlaying && (!mplayer.isPaused)) {
		[mplayer setSpeed:[mplayer.movieInfo.playingInfo.speed floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.speed floatValue];
}

-(float) changeSubDelayBy:(float) delta
{
	if (mplayer.isPlaying && (!mplayer.isPaused)) {
		[mplayer setSubDelay:[mplayer.movieInfo.playingInfo.subDelay floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.subDelay floatValue];
}

-(float) changeAudioDelayBy:(float) delta
{
	if (mplayer.isPlaying && (!mplayer.isPaused)) {
		[mplayer setAudioDelay:[mplayer.movieInfo.playingInfo.audioDelay floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.audioDelay floatValue];	
}

-(float) changeSubScaleBy:(float) delta
{
	if (mplayer.isPlaying && (!mplayer.isPaused)) {
		[mplayer setSubScale: [mplayer.movieInfo.playingInfo.subScale floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.subScale floatValue];
}

-(float) setSpeed:(float) spd
{
	if (mplayer.isPlaying && (!mplayer.isPaused)) {
		[mplayer setSpeed:spd];
	}
	return [mplayer.movieInfo.playingInfo.speed floatValue];
}

-(float) setSubDelay:(float) sd
{
	if (mplayer.isPlaying && (!mplayer.isPaused)) {
		[mplayer setSubDelay:sd];
	}
	return [mplayer.movieInfo.playingInfo.subDelay floatValue];	
}

-(float) setAudioDelay:(float) ad
{
	if (mplayer.isPlaying && (!mplayer.isPaused)) {
		[mplayer setAudioDelay:ad];
	}
	return [mplayer.movieInfo.playingInfo.audioDelay floatValue];	
}

-(void) setSubtitle:(int) subID
{
	[mplayer setSub:subID];
}

/////////////////////////////////////Actions//////////////////////////////////////
-(IBAction) openFile:(id) sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setResolvesAliases:NO];
	// 现在还不支持播放列表，因此禁用多选择
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:NO];
	[openPanel setTitle:NSLocalizedString(@"Open Media Files", nil)];
	
	if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
		[self playMedia:[[openPanel URLs] objectAtIndex:0]];
	}
}

/////////////////////////////////////Application Delegate//////////////////////////////////////
-(BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	[self playMedia:[NSURL fileURLWithPath:filename isDirectory:NO]];
	return YES;
}

-(void) application:(NSApplication *)theApplication openFiles:(NSArray *)filenames
{
	[self playMedia:[NSURL fileURLWithPath:[filenames objectAtIndex:0] isDirectory:NO]];
	[theApplication replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

-(NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	[mplayer performStop];
	lastPlayedPath = nil;
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	return NSTerminateNow;	
}

-(void) applicationDidFinishLaunching:(NSNotification *)notification
{
	[[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}
////////////////////////////////////////Window Delegate////////////////////////////////////////
-(void) windowWillClose:(NSNotification *)notification
{
	[mplayer performStop];
	// 窗口一旦关闭，清理lastPlayPath，则即使再次打开窗口也不会播放以前的文件
	lastPlayedPath = nil;
}

@end
