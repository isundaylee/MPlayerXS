/*
 * MPlayerX - PlayerController.m
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
#import "PlayerController.h"
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

#define kMPCDefaultSubFontPath				(@"wqy-microhei.ttc")

@interface PlayerController (CoreControllerNotification)
-(void) mplayerStarted:(NSNotification *)notification;
-(void) mplayerStopped:(NSNotification *)notification;
-(void) preventSystemSleep;
-(void) tryToPlayNext;
@end

@implementation PlayerController

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
					   [NSNumber numberWithBool:NO], kUDKeyQuitOnClose,
					   [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]], kUDKeySubFontColor,
					   [NSArchiver archivedDataWithRootObject:[NSColor blackColor]], kUDKeySubFontBorderColor,
					   [NSNumber numberWithBool:NO], kUDKeyForceIndex,
					   [NSNumber numberWithUnsignedInt:kSubFileNameRuleContain], kUDKeySubFileNameRule,
					   @"http://mplayerx.googlecode.com/svn/trunk/update/appcast.xml", @"SUFeedURL",
					   @"http://code.google.com/p/mplayerx/wiki/Help?tm=6", kUDKeyHelpURL,
					   nil]];
}

#pragma mark Init/Dealloc
-(id) init
{
	if (self = [super init]) {
		ud = [NSUserDefaults standardUserDefaults];
		
		mplayer = [[CoreController alloc] init];
		lastPlayedPath = nil;
		lastPlayedPathPre = nil;
		supportVideoFormats = nil;
		supportAudioFormats = nil;
		bookmarks = nil;
	}
	return self;
}

-(BOOL) shouldRun64bitMPlayer
{
	int value = 0 ;
	unsigned long length = sizeof(value);
	
	if ((sysctlbyname("hw.optional.x86_64", &value, &length, NULL, 0) == 0) && (value == 1))
		return [ud boolForKey:kUDKeyPrefer64bitMPlayer];
	
	return NO;
}

-(void) awakeFromNib
{
	// 初始化CoreController
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *homeDirectory = NSHomeDirectory();
	
	[aboutText setStringValue:[NSString stringWithFormat: @"MPlayerX %@\nby Niltsh@2009\nhttp://code.google.com/p/mplayerx/\nzongyao.qu@gmail.com\n\nThanks to\n\nmplayer\nhttp://www.mplayerhq.hu\n\nUniversalDetector\nhttp://wakaba.c3.cx/s/apps/unarchiver.html\n\nBGHUDAppKit\nhttp://www.binarymethod.com/bghudappkit/\n\nWenQuan MicroHei Font\nhttp://www.wenq.org", 
															[mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];

	
	[self setMultiThreadMode:[ud boolForKey:kUDKeyEnableMultiThread]];
	
	// 得到字幕字体文件的路径
	NSString *subFontPath = [ud stringForKey:kUDKeySubFontPath];
	
	if ([subFontPath isEqualToString:kMPCDefaultSubFontPath]) {
		// 如果是默认的路径的话，需要添加一些路径头
		[mplayer.pm setSubFont:[[mainBundle resourcePath] stringByAppendingPathComponent:subFontPath]];
	} else {
		// 否则直接设定
		[mplayer.pm setSubFont:subFontPath];
	}
	
	// 决定是否使用64bit的mplayer
	[mplayer.pm setPrefer64bMPlayer:[self shouldRun64bitMPlayer]];
	
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
				 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
				 context:NULL];
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringCurrentTime
				 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
				 context:NULL];
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringSeekable
				 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
				 context:NULL];
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringSpeed
				 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
				 context:NULL];
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringSubDelay
				 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
				 context:NULL];
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringAudioDelay
				 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
				 context:NULL];
	[mplayer addObserver:self
			  forKeyPath:kObservedValueStringSubInfo
				 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
				 context:NULL];

	// 建立支持格式的Set
	for( NSDictionary *dict in [mainBundle objectForInfoDictionaryKey:@"CFBundleDocumentTypes"]) {
		// 对不同种类的格式
		if ([[dict objectForKey:@"CFBundleTypeName"] isEqualToString:@"Audio Media"]) {
			// 如果是音频文件
			supportAudioFormats = [[NSSet alloc] initWithArray:[dict objectForKey:@"CFBundleTypeExtensions"]];
		} else if ([[dict objectForKey:@"CFBundleTypeName"] isEqualToString:@"Video Media"]) {
			//如果是视频文件
			supportVideoFormats = [[NSSet alloc] initWithArray:[dict objectForKey:@"CFBundleTypeExtensions"]];
		}
	}
	
	// 得到书签的文件名
	NSString *lastStoppedTimePath = [NSString stringWithFormat:@"%@/Library/Preferences/%@.bookmarks.plist", 
															   homeDirectory, [mainBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
	
	// 得到记录播放时间的dict
	bookmarks = [[NSMutableDictionary alloc] initWithContentsOfFile:lastStoppedTimePath];
	if (!bookmarks) {
		// 如果文件不存在或者格式非法
		bookmarks = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	
	// 设定手动更新
	[[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:NO];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	NSString *workDir = [homeDirectory stringByAppendingPathComponent:@"Library/Application Support/MPlayerX"];

	if (!([fm fileExistsAtPath:workDir isDirectory:&isDir] && isDir)) {
		// 如果没有这个文件夹
		if (![fm createDirectoryAtPath:workDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
			// 如果文件夹创建失败
			workDir = nil;
		}
	}
	[mplayer setWorkDirectory:workDir];
	
	// 开启Timer防止睡眠
	NSTimer *prevSlpTimer = [NSTimer timerWithTimeInterval:20 
													target:self
												  selector:@selector(preventSystemSleep)
												  userInfo:nil
												   repeats:YES];
	NSRunLoop *rl = [NSRunLoop mainRunLoop];
	[rl addTimer:prevSlpTimer forMode:NSDefaultRunLoopMode];
	[rl addTimer:prevSlpTimer forMode:NSModalPanelRunLoopMode];
	[rl addTimer:prevSlpTimer forMode:NSEventTrackingRunLoopMode];
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
	[supportVideoFormats release];
	[supportAudioFormats release];
	
	[bookmarks release];

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
	if (mplayer.state == kMPCPlayingState) {
		UpdateSystemActivity(UsrActivity);
	}
}

-(void) setDelegateForMPlayer:(id<MPlayerDisplayDelegate>) delegate
{
	[mplayer setDispDelegate:delegate];
}

-(int) playerState
{
	return mplayer.state;
}

-(void) refreshParameters
{
	// 将播放开始时间重置
	[mplayer.pm setStartTime:-1];
	// 设定字幕大小
	[mplayer.pm setSubScale:[ud floatForKey:kUDKeySubScale]];
	
	[mplayer.pm setSubFontColor:
	 [NSUnarchiver unarchiveObjectWithData:
	  [ud objectForKey:kUDKeySubFontColor]]];
	
	[mplayer.pm setSubFontBorderColor:
	 [NSUnarchiver unarchiveObjectWithData:
	  [ud objectForKey:kUDKeySubFontBorderColor]]];
	
	[mplayer.pm setForceIndex:[ud boolForKey:kUDKeyForceIndex]];
	[mplayer.pm setSubNameRule:[ud integerForKey:kUDKeySubFileNameRule]];
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
			if ((supportVideoFormats && [supportVideoFormats containsObject:[path pathExtension]]) ||
				(supportAudioFormats && [supportAudioFormats containsObject:[path pathExtension]])) {
				BOOL isDir = YES;
				if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && (!isDir)) {
					// 为了保险期间，每次播放开始的时候
					[self refreshParameters];
					
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
			
			[self refreshParameters];
			
			lastPlayedPathPre = [NSString stringWithString:path];
			[mplayer playMedia:lastPlayedPathPre];
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
							 [resPath stringByAppendingPathComponent:[NSString stringWithFormat:@"binaries/m32/%@", mplayerName]], kI386Key,
							 [resPath stringByAppendingPathComponent:[NSString stringWithFormat:@"binaries/x86_64/%@", mplayerName]], kX86_64Key,
							 nil]];
}

///////////////////////////////////////MPlayer Notifications/////////////////////////////////////////////
-(void) mplayerStarted:(NSNotification *)notification
{
	[window setTitle:[lastPlayedPathPre lastPathComponent]];
	
	[controlUI playBackStarted];
	
	// 用文件名查找有没有之前的播放记录
	NSNumber *stopTime = [bookmarks objectForKey:lastPlayedPathPre];
	// NSLog(@"Pre:%@", lastPlayedPathPre);
	if (stopTime) {
		// 有的话，通知controlUI
		[controlUI gotLastStoppedPlace:[stopTime floatValue]];
	}
}

-(void) mplayerStopped:(NSNotification *)notification
{	
	[window setTitle: @"MPlayerX"];
	
	[controlUI playBackStopped];
	
	if ([[[notification userInfo] objectForKey:kMPCPlayStoppedByForceKey] boolValue]) {
		// 如果是强制停止
		// 用文件名做key，记录这个文件的播放时间
		[bookmarks setObject:[[notification userInfo] objectForKey:kMPCPlayStoppedTimeKey] forKey:lastPlayedPath];
	} else {
		// 自然关闭
		// 删除这个文件key的播放时间
		[bookmarks removeObjectForKey:lastPlayedPath];
	}
	// NSLog(@"StopPath:%@", lastPlayedPath);
	
	if ([ud boolForKey:kUDKeyAutoPlayNext] && 
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
			return;
		}
	}

	// 如果不继续播放，或者没有下一个播放文件，那么退出全屏
	// 这个时候的显示状态displaying是NO
	// 因此，如果是全屏的话，会退出全屏，如果不是全屏的话，也不会进入全屏
	[controlUI toggleFullScreen:nil];
	// 并且重置 fillScreen状态
	[controlUI toggleFillScreen:nil];
}

-(void) tryToPlayNext
{
	if ([ud boolForKey:kUDKeyAutoPlayNext] && 
		(mplayer.state == kMPCStoppedState)
	   ) {
		//如果不是本地文件，肯定返回nil
		NSString *nextPath = [PlayList AutoSearchNextMoviePathFrom:lastPlayedPath];
		if (nextPath != nil) {
			[self playMedia:[NSURL fileURLWithPath:nextPath isDirectory:NO]];
			// 如果能够播放，并且有东西放，就直接结束
			return;
		}
	}
	// 如果不继续播放，或者没有下一个播放文件，那么退出全屏
	// 这个时候的显示状态displaying是NO
	// 因此，如果是全屏的话，会退出全屏，如果不是全屏的话，也不会进入全屏
	[controlUI toggleFullScreen:nil];
	// 并且重置 fillScreen状态
	[controlUI toggleFillScreen:nil];
}

////////////////////////////////////////////////cooperative actions with UI//////////////////////////////////////////////////
-(void) togglePlayPause
{
	if (mplayer.state != kMPCStoppedState) {
		// mplayer正在播放
		[mplayer togglePause];
	} else {
		//mplayer不在播放状态
		// 想播放
		if (lastPlayedPath) {
			// 有可以播放的文件
			[self playMedia:[NSURL fileURLWithPath:lastPlayedPath isDirectory:NO]];
		}
	}
}

-(BOOL) toggleMute
{
	return (mplayer.state != kMPCStoppedState)? ([mplayer setMute:!mplayer.movieInfo.playingInfo.mute]):NO;
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
	if ((mplayer.state != kMPCStoppedState) && mplayer.movieInfo.seekable) {
		time = [mplayer setTimePos:time];
		[mplayer.la stop];
		return time;
	}
	return -1;
}

-(float) changeTimeBy:(float) delta
{
	// playingInfo的currentTime是通过获取log来同步的，因此这里不进行直接设定
	if ((mplayer.state != kMPCStoppedState) && mplayer.movieInfo.seekable) {
		delta = [mplayer setTimePos:[mplayer.movieInfo.playingInfo.currentTime floatValue] + delta];	
		[mplayer.la stop];
		return delta;
	}
	return -1;
}

-(float) changeSpeedBy:(float) delta
{
	if (mplayer.state != kMPCStoppedState) {
		[mplayer setSpeed:[mplayer.movieInfo.playingInfo.speed floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.speed floatValue];
}

-(float) changeSubDelayBy:(float) delta
{
	if (mplayer.state != kMPCStoppedState) {
		[mplayer setSubDelay:[mplayer.movieInfo.playingInfo.subDelay floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.subDelay floatValue];
}

-(float) changeAudioDelayBy:(float) delta
{
	if (mplayer.state != kMPCStoppedState) {
		[mplayer setAudioDelay:[mplayer.movieInfo.playingInfo.audioDelay floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.audioDelay floatValue];	
}

-(float) changeSubScaleBy:(float) delta
{
	if (mplayer.state != kMPCStoppedState) {
		[mplayer setSubScale: [mplayer.movieInfo.playingInfo.subScale floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.subScale floatValue];
}

-(float) changeSubPosBy:(float)delta
{
	if (mplayer.state != kMPCStoppedState) {
		[mplayer setSubPos: mplayer.movieInfo.playingInfo.subPos + delta*100];
	}
	return mplayer.movieInfo.playingInfo.subPos;
}

-(float) changeAudioBalanceBy:(float)delta
{
	if (mplayer.state != kMPCStoppedState) {
		[mplayer setBalance:mplayer.movieInfo.playingInfo.audioBalance + delta];
	}
	return mplayer.movieInfo.playingInfo.audioBalance;
}

-(float) setSpeed:(float) spd
{
	if (mplayer.state != kMPCStoppedState) {
		[mplayer setSpeed:spd];
	}
	return [mplayer.movieInfo.playingInfo.speed floatValue];
}

-(float) setSubDelay:(float) sd
{
	if (mplayer.state != kMPCStoppedState) {
		[mplayer setSubDelay:sd];
	}
	return [mplayer.movieInfo.playingInfo.subDelay floatValue];	
}

-(float) setAudioDelay:(float) ad
{
	if (mplayer.state != kMPCStoppedState) {
		[mplayer setAudioDelay:ad];
	}
	return [mplayer.movieInfo.playingInfo.audioDelay floatValue];	
}

-(void) setSubtitle:(int) subID
{
	[mplayer setSub:subID];
}

-(void) setAudio:(int) audioID
{
	[mplayer setAudio:audioID];
}

-(void) setAudioBalance:(float)bal
{
	[mplayer setBalance:bal];
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

-(IBAction) showHelp:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[ud stringForKey:kUDKeyHelpURL]]];
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

	[ud synchronize];

	NSString *lastStoppedTimePath = [NSString stringWithFormat:@"%@/Library/Preferences/%@.bookmarks.plist", 
															   NSHomeDirectory(), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]];

	[bookmarks writeToFile:lastStoppedTimePath atomically:YES];
	
	return NSTerminateNow;	
}

-(void) applicationDidFinishLaunching:(NSNotification *)notification
{
	[[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}
////////////////////////////////////////Window Delegate////////////////////////////////////////
-(void) windowWillClose:(NSNotification *)notification
{
	if ([ud boolForKey:kUDKeyQuitOnClose]) {
		[NSApp terminate:self];
	} else {
		[mplayer performStop];
		// 窗口一旦关闭，清理lastPlayPath，则即使再次打开窗口也不会播放以前的文件
		lastPlayedPath = nil;		
	}
}

@end
