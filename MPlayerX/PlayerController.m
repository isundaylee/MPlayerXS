/*
 * MPlayerX - PlayerController.m
 *
 * Copyright (C) 2009 Zongyao QU
 * 
 * MPlayerX is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * MPlayerX is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with MPlayerX; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "def.h"
#import "LocalizedStrings.h"
#import "PlayerController.h"
#import "PlayList.h"
#import <sys/sysctl.h>
#import <Sparkle/Sparkle.h>
#import "OpenURLController.h"
#import "CharsetQueryController.h"

NSString * const kMPCPlayOpenedNotification			= @"kMPCPlayOpenedNotification";
NSString * const kMPCPlayOpenedURLKey				= @"kMPCPlayOpenedURLKey";
NSString * const kMPCPlayLastStoppedTimeKey			= @"kMPCPlayLastStoppedTimeKey";

NSString * const kMPCPlayStartedNotification		= @"kMPCPlayStartedNotification";
NSString * const kMPCPlayStartedAudioOnlyKey		= @"kMPCPlayStartedAudioOnlyKey";

NSString * const kMPCPlayStoppedNotification		= @"kMPCPlayStoppedNotification";
NSString * const kMPCPlayWillStopNotification		= @"kMPCPlayWillStopNotification";
NSString * const kMPCPlayFinalizedNotification		= @"kMPCPlayFinalizedNotification";

NSString * const kMPCPlayInfoUpdatedNotification	= @"kMPCPlayInfoUpdatedNotification";
NSString * const kMPCPlayInfoUpdatedKeyPathKey		= @"kMPCPlayInfoUpdatedKeyPathKey";
NSString * const kMPCPlayInfoUpdatedChangeDictKey	= @"kMPCPlayInfoUpdatedChangeDictKey";

NSString * const kMPCDefaultSubFontPath			= @"wqy-microhei.ttc";

NSString * const kMPCFMTBookmarkPath	= @"%@/Library/Preferences/%@.bookmarks.plist";

NSString * const kMPCMplayerNameMT		= @"mplayer-mt";
NSString * const kMPCMplayerName		= @"mplayer";
NSString * const kMPCFMTMplayerPathM32	= @"binaries/m32/%@";
NSString * const kMPCFMTMplayerPathX64	= @"binaries/x86_64/%@";

NSString * const kMPCFFMpegProtoHead	= @"ffmpeg://";

#define kThreadsNumMax	(8)

#define SAFERELEASE(x)		{if(x) {[x release];x = nil;}}

#define PlayerCouldAcceptCommand	(((mplayer.state) & 0x0100)!=0)

@interface PlayerController (CoreControllerDelegate)
-(void) playebackOpened;
-(void) playebackStarted;
-(void) playebackStopped:(NSDictionary*)dict;
-(void) playebackWillStop;
@end

@interface PlayerController (PlayerControllerInternal)
-(void) preventSystemSleep;
-(void) playMedia:(NSURL*)url;
-(NSURL*) findFirstMediaFileFromSubFile:(NSString*)path;
@end

@interface PlayerController (SubConverterDelegate)
-(NSString*) subConverter:(SubConverter*)subConv detectedFile:(NSString*)path ofCharsetName:(NSString*)charsetName confidence:(float)confidence;
@end

@implementation PlayerController

@synthesize lastPlayedPath;

+(void) initialize
{
	NSNumber *boolYes = [NSNumber numberWithBool:YES];
	NSNumber *boolNo  = [NSNumber numberWithBool:NO];
	
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   boolYes, kUDKeyAutoPlayNext,
					   kMPCDefaultSubFontPath, kUDKeySubFontPath,
					   boolYes, kUDKeyPrefer64bitMPlayer,
					   boolYes, kUDKeyEnableMultiThread,
					   [NSNumber numberWithFloat:1.0], kUDKeySubScale,
					   [NSNumber numberWithFloat:0.1], kUDKeySubScaleStepValue,
					   [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:1.0 alpha:1.00]], kUDKeySubFontColor,
					   [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:0.0 alpha:0.85]], kUDKeySubFontBorderColor,
					   boolNo, kUDKeyForceIndex,
					   [NSNumber numberWithUnsignedInt:kSubFileNameRuleContain], kUDKeySubFileNameRule,
					   boolNo, kUDKeyDTSPassThrough,
					   boolNo, kUDKeyAC3PassThrough,
					   [NSNumber numberWithUnsignedInt:1], kUDKeyThreadNum,
					   boolYes, kUDKeyUseEmbeddedFonts,
					   [NSNumber numberWithUnsignedInt:5000], kUDKeyCacheSize,
					   boolYes, kUDKeyPreferIPV6,
					   boolNo, kUDKeyCachingLocal,
					   [NSNumber numberWithUnsignedInt:kPMLetterBoxModeNotDisplay], kUDKeyLetterBoxMode,
					   [NSNumber numberWithUnsignedInt:kPMLetterBoxModeBottomOnly], kUDKeyLetterBoxModeAlt,
					   [NSNumber numberWithFloat:0.1], kUDKeyLetterBoxHeight,
					   boolYes, kUDKeyPlayWhenOpened,
					   boolYes, kUDKeyOverlapSub,
					   boolYes, kUDKeyRtspOverHttp,
					   [NSNumber numberWithUnsignedInt:kPMMixDTS5_1ToStereo], kUDKeyMixToStereoMode,
					   @"http://mplayerx.googlecode.com/svn/trunk/update/appcast.xml", @"SUFeedURL",
					   @"http://code.google.com/p/mplayerx/wiki/Help?tm=6", kUDKeyHelpURL,
					   nil]];
}

#pragma mark Init/Dealloc
-(id) init
{
	if (self = [super init]) {
		ud = [NSUserDefaults standardUserDefaults];
		notifCenter = [NSNotificationCenter defaultCenter];
		
		mplayer = [[CoreController alloc] init];
		[mplayer setDelegate:self];
		
		lastPlayedPath = nil;
		lastPlayedPathPre = nil;
		supportVideoFormats = nil;
		supportAudioFormats = nil;
		supportSubFormats = nil;
		bookmarks = nil;
		
		kvoSetuped = NO;
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

-(void) setupKVO
{
	if (!kvoSetuped) {
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathLength
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathCurrentTime
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathSeekable
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathSpeed
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathSubDelay
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathAudioDelay
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathSubInfo
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathCachingPercent
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathAudioInfo
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathVideoInfo
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		kvoSetuped = YES;	
	}
}

-(void) awakeFromNib
{
	// 初始化CoreController
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *homeDirectory = NSHomeDirectory();
	
	[aboutText setStringValue:[NSString stringWithFormat: @"MPlayerX %@ (r%@) by Zongyao QU@2009,2010", 
							   [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
							   [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]]];
	
	/////////////////////////setup CoreController////////////////////
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

	/////////////////////////setup self////////////////////
	// 建立支持格式的Set
	for( NSDictionary *dict in [mainBundle objectForInfoDictionaryKey:@"CFBundleDocumentTypes"]) {

		NSString *obj = [dict objectForKey:@"CFBundleTypeName"];
		// 对不同种类的格式
		if ([obj isEqualToString:@"Audio Media"]) {
			// 如果是音频文件
			supportAudioFormats = [[NSSet alloc] initWithArray:[dict objectForKey:@"CFBundleTypeExtensions"]];
		
		} else if ([obj isEqualToString:@"Video Media"]) {
			// 如果是视频文件
			supportVideoFormats = [[NSSet alloc] initWithArray:[dict objectForKey:@"CFBundleTypeExtensions"]];
		} else if ([obj isEqualToString:@"Subtitle"]) {
			// 如果是字幕文件
			supportSubFormats = [[NSSet alloc] initWithArray:[dict objectForKey:@"CFBundleTypeExtensions"]];
		}
	}
	
	/////////////////////////setup bookmarks////////////////////
	// 得到书签的文件名
	NSString *lastStoppedTimePath = [NSString stringWithFormat:kMPCFMTBookmarkPath, 
															   homeDirectory, [mainBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
	// 得到记录播放时间的dict
	bookmarks = [[NSMutableDictionary alloc] initWithContentsOfFile:lastStoppedTimePath];
	if (!bookmarks) {
		// 如果文件不存在或者格式非法
		bookmarks = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	[openUrlController initURLList:bookmarks];
	
	/////////////////////////setup auto update////////////////////
	// 设定手动更新
	[[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:NO];
	
	/////////////////////////setup subconverter////////////////////
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	NSString *workDir = [[[fm URLForDirectory:NSApplicationSupportDirectory
									 inDomain:NSUserDomainMask
							appropriateForURL:NULL
									   create:YES
										error:NULL] path] stringByAppendingPathComponent:kMPCStringMPlayerX];

	if ([fm fileExistsAtPath:workDir isDirectory:&isDir] && (!isDir)) {
		// 如果存在但不是文件夹的话
		[fm removeItemAtPath:workDir error:NULL];
	}
	if (!isDir) {
		// 如果原来不存在这个文件夹或者存在的是文件的话，都需要重建文件夹
		if (![fm createDirectoryAtPath:workDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
			workDir = nil;
		}
	}
	[mplayer setWorkDirectory:workDir];
	
	[mplayer setSubConverterDelegate:self];
	
	/////////////////////////setup sleep timer////////////////////
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
	if (kvoSetuped) {
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathCurrentTime];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathLength];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathSeekable];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathSpeed];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathSubDelay];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathAudioDelay];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathSubInfo];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathCachingPercent];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathAudioInfo];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathVideoInfo];
		kvoSetuped = NO;
	}

	[mplayer release];
	[lastPlayedPath release];
	[supportVideoFormats release];
	[supportAudioFormats release];
	[supportSubFormats release];
	
	[bookmarks release];

	[super dealloc];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == mplayer) {
		[notifCenter postNotificationName:kMPCPlayInfoUpdatedNotification object:self
								 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										   keyPath, kMPCPlayInfoUpdatedKeyPathKey,
										   change, kMPCPlayInfoUpdatedChangeDictKey, nil]];
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

-(id) setDisplayDelegateForMPlayer:(id<CoreDisplayDelegate>) delegate
{
	[mplayer setDispDelegate:delegate];
	return mplayer;
}

-(int) playerState
{
	return mplayer.state;
}

-(BOOL) couldAcceptCommand
{
	return PlayerCouldAcceptCommand;
}

-(id) mediaInfo
{
	return [mplayer movieInfo];
}

-(NSString*) subConverter:(SubConverter*)subConv detectedFile:(NSString*)path ofCharsetName:(NSString*)charsetName confidence:(float)confidence
{
	NSString *ret = nil;
	
	if (confidence <= [ud floatForKey:kUDKeyTextSubtitleCharsetConfidenceThresh]) {
		// 当置信率小于阈值时
		CFStringEncoding ce;
		
		if ([ud boolForKey:kUDKeyTextSubtitleCharsetManual]) {
			// 如果是手动指定的话
			ce = [charsetController askForSubEncodingForFile:path charsetName:charsetName confidence:confidence];
		} else {
			// 如果是自动fallback
			ce = [ud integerForKey:kUDKeyTextSubtitleCharsetFallback];
		}
		ret = (NSString*)CFStringConvertEncodingToIANACharSetName(ce);
	}
	return ret;
}

-(void) loadFiles:(NSArray*)files fromLocal:(BOOL)local
{
	if (files) {
		NSString *path;
		BOOL isDir = YES;
		NSFileManager *fm = [NSFileManager defaultManager];

		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		for (id file in files) {
			// 如果是字符串的话先转到URL

			if ([file isKindOfClass:[NSString class]]) {
				if (local) {
					file = [NSURL fileURLWithPath:file isDirectory:NO];
				} else {
					file = [NSURL URLWithString:file];
				}
			}
			
			if (file && [file isKindOfClass:[NSURL class]]) {
				if ([file isFileURL]) {
					// 如果是本地文件
					path = [file path];
					isDir = YES;
					
					if ([fm fileExistsAtPath:path isDirectory:&isDir] && (!isDir)) {
						// 如果文件存在
						NSString *ext = [[path pathExtension] lowercaseString];
						
						if ([supportVideoFormats containsObject:ext] || [supportAudioFormats containsObject:ext]) {
							// 如果是支持的格式
							[self playMedia:file];
							break;
							
						} else if ([supportSubFormats containsObject:ext]) {
							// 如果是字幕文件
							if (PlayerCouldAcceptCommand) {
								// 如果是在播放状态，就加载字幕
								[self loadSubFile:path];
							} else {
								// 如果是在停止状态，那么应该是想打开媒体文件先
								// 需要根据字幕文件名去寻找影片文件
								NSURL *autoSearchMediaFile = nil;
								if (autoSearchMediaFile = [self findFirstMediaFileFromSubFile:path]) {
									// 如果找到了
									[self playMedia:autoSearchMediaFile];
								}
								// 不管有没有找到，都需要break
								// 找到了就播放
								// 没有找到。说明按照当前的文件名规则并不存在相应的媒体文件
								if (!autoSearchMediaFile) {
									// 如果没有找到合适的播放文件
									id alertPanel = NSGetAlertPanel(kMPXStringError, kMPXStringCantFindMediaFile, kMPXStringOK, nil, nil);
									[NSApp runModalForWindow:alertPanel];
									NSReleaseAlertPanel(alertPanel);
								}
								break;
							}
						} else {
							// 否则提示
							id alertPanel = NSGetAlertPanel(kMPXStringError, kMPXStringFileNotSupported, kMPXStringOK, nil, nil);
							[NSApp runModalForWindow:alertPanel];
							NSReleaseAlertPanel(alertPanel);
						}
					} else {
						// 文件不存在
						id alertPanel = NSGetAlertPanel(kMPXStringError, kMPXStringFileNotExist, kMPXStringOK, nil, nil);
						[NSApp runModalForWindow:alertPanel];
						NSReleaseAlertPanel(alertPanel);
					}
				} else {
					// 如果是非本地文件
					[self playMedia:file];
					break;
				}				
			}
		}
		[pool drain];
	}
}

-(void) playMedia:(NSURL*)url
{
	// 内部函数，没有那么必要判断url的有效性
	NSString *path;	
	// 将播放开始时间重置
	[mplayer.pm setStartTime:-1];
	// 设定字幕大小
	[mplayer.pm setSubScale:[ud floatForKey:kUDKeySubScale]];
	
	[mplayer.pm setSubFontColor: [NSUnarchiver unarchiveObjectWithData: [ud objectForKey:kUDKeySubFontColor]]];
	
	[mplayer.pm setSubFontBorderColor: [NSUnarchiver unarchiveObjectWithData: [ud objectForKey:kUDKeySubFontBorderColor]]];
	
	[mplayer.pm setForceIndex:[ud boolForKey:kUDKeyForceIndex]];
	[mplayer.pm setSubNameRule:[ud integerForKey:kUDKeySubFileNameRule]];
	[mplayer.pm setDtsPass:[ud boolForKey:kUDKeyDTSPassThrough]];
	[mplayer.pm setAc3Pass:[ud boolForKey:kUDKeyAC3PassThrough]];
	[mplayer.pm setUseEmbeddedFonts:[ud boolForKey:kUDKeyUseEmbeddedFonts]];
	
	[mplayer.pm setLetterBoxMode:[ud integerForKey:kUDKeyLetterBoxMode]];
	[mplayer.pm setLetterBoxHeight:[ud floatForKey:kUDKeyLetterBoxHeight]];
	[mplayer.pm setPauseAtStart:![ud boolForKey:kUDKeyPlayWhenOpened]];
	[mplayer.pm setOverlapSub:[ud boolForKey:kUDKeyOverlapSub]];
	[mplayer.pm setMixToStereo:[ud integerForKey:kUDKeyMixToStereoMode]];
	 
	// 这里必须要retain，否则如果用lastPlayedPath作为参数传入的话会有问题
	lastPlayedPathPre = [[url absoluteURL] retain];
	
	if ([url isFileURL]) {
		// local files
		path = [url path];

		[mplayer.pm setCache:([ud boolForKey:kUDKeyCachingLocal])?([ud integerForKey:kUDKeyCacheSize]):(0)];
		[mplayer.pm setRtspOverHttp:NO];
		
		// 将文件加入Recent Menu里，只能加入本地文件
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];

	} else {
		// network stream
		path = [url absoluteString];
		
		[mplayer.pm setCache:[ud integerForKey:kUDKeyCacheSize]];
		[mplayer.pm setPreferIPV6:[ud boolForKey:kUDKeyPreferIPV6]];
		[mplayer.pm setRtspOverHttp:[ud boolForKey:kUDKeyRtspOverHttp]];
		
		// 将URL加入OpenURLController
		[openUrlController addUrl:path];

		if ([ud boolForKey:kUDKeyFFMpegHandleStream] != ([NSEvent modifierFlags]==kSCMFFMpegHandleStreamShortCurKey)) {
			path = [kMPCFFMpegProtoHead stringByAppendingString:path];
		}
	}

	[mplayer playMedia:path];

	// NSLog(@"%@", path);
	
	SAFERELEASE(lastPlayedPath);
	lastPlayedPath = lastPlayedPathPre;
	lastPlayedPathPre = nil;
}

-(NSURL*) findFirstMediaFileFromSubFile:(NSString*)path
{
	// 需要先得到 nameRule的最新值
	[mplayer.pm setSubNameRule:[ud integerForKey:kUDKeySubFileNameRule]];

	// 得到最新的nameRule
	SUBFILE_NAMERULE nameRule = [mplayer.pm subNameRule];
	
	NSURL *mediaURL = nil;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// 文件夹路径
	NSString *directoryPath = [path stringByDeletingLastPathComponent];
	// 字幕文件名称
	NSString *subName = [[path lastPathComponent] stringByDeletingPathExtension];

	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];

	// 遍历播放文件所在的目录
	for (NSString *mediaFile in directoryEnumerator)
	{
		// TODO 这里需要检查mediaFile是文件名还是 路径名
		NSDictionary *fileAttr = [directoryEnumerator fileAttributes];
		NSString *ext = [[mediaFile pathExtension] lowercaseString];
		
		if ([[fileAttr objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
			//不遍历子目录
			[directoryEnumerator skipDescendants];

		} else if ([[fileAttr objectForKey:NSFileType] isEqualToString: NSFileTypeRegular] &&
					([supportVideoFormats containsObject:ext] || [supportAudioFormats containsObject:ext])) {
			// 如果是正常文件，并且是媒体文件
			NSString *mediaName = [mediaFile stringByDeletingPathExtension];
			
			switch (nameRule) {
				case kSubFileNameRuleExactMatch:
					if (![mediaName isEqualToString:subName]) continue; // exact match
					break;
				case kSubFileNameRuleAny:
					break; // any sub file is OK
				case kSubFileNameRuleContain:
					if ([subName rangeOfString: mediaName].location == NSNotFound) continue; // contain the movieName
					break;
				default:
					continue;
					break;				
			}
			// 能到这里说明找到了一个合适的播放文件, 跳出循环
			mediaURL = [[NSURL fileURLWithPath:[directoryPath stringByAppendingPathComponent:mediaFile] isDirectory:NO] retain];
			break;
		}
	}
	[pool drain];
	return [mediaURL autorelease];
}

-(void) setMultiThreadMode:(BOOL) mt
{
	NSString *resPath = [[NSBundle mainBundle] resourcePath];
	
	NSString *mplayerName;
	unsigned int threadNum;
	
	if (/*mt*/1) {
		// 使用多线程
		threadNum = MIN(kThreadsNumMax, MAX(2,[ud integerForKey:kUDKeyThreadNum]));
		mplayerName = kMPCMplayerNameMT;
	} else {
		threadNum = MIN(kThreadsNumMax, MAX(1,[ud integerForKey:kUDKeyThreadNum]));
		mplayerName = kMPCMplayerName;
	}

	[ud setInteger:threadNum forKey:kUDKeyThreadNum];
	
	[mplayer.pm setThreads: threadNum];
	
	[mplayer setMpPathPair: [NSDictionary dictionaryWithObjectsAndKeys: 
							 [resPath stringByAppendingPathComponent:[NSString stringWithFormat:kMPCFMTMplayerPathM32, mplayerName]], kI386Key,
							 [resPath stringByAppendingPathComponent:[NSString stringWithFormat:kMPCFMTMplayerPathX64, mplayerName]], kX86_64Key,
							 nil]];
}

///////////////////////////////////////MPlayer Notifications/////////////////////////////////////////////
-(void) playebackOpened
{
	// 用文件名查找有没有之前的播放记录
	NSNumber *stopTime = [bookmarks objectForKey:[lastPlayedPathPre absoluteString]];
	NSDictionary *dict;

	if (stopTime) {
		dict = [NSDictionary dictionaryWithObjectsAndKeys:
				lastPlayedPathPre, kMPCPlayOpenedURLKey, 
				stopTime, kMPCPlayLastStoppedTimeKey,
				nil];
	} else {
		dict = [NSDictionary dictionaryWithObjectsAndKeys: lastPlayedPathPre, kMPCPlayOpenedURLKey, nil];		
	}

	[notifCenter postNotificationName:kMPCPlayOpenedNotification object:self userInfo:dict];
}

-(void) playebackStarted
{
	[notifCenter postNotificationName:kMPCPlayStartedNotification object:self 
							 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithBool:([mplayer.movieInfo.videoInfo count] == 0)], kMPCPlayStartedAudioOnlyKey,
									   nil]];

	NSLog(@"vc:%d, ac:%d", [mplayer.movieInfo.videoInfo count], [mplayer.movieInfo.audioInfo count]);
}

-(void) playebackWillStop
{
	[notifCenter postNotificationName:kMPCPlayWillStopNotification object:self userInfo:nil];
}

-(void) playebackStopped:(NSDictionary*)dict
{	
	BOOL stoppedByForce = [[dict objectForKey:kMPCPlayStoppedByForceKey] boolValue];

	[notifCenter postNotificationName:kMPCPlayStoppedNotification object:self userInfo:nil];

	if (stoppedByForce) {
		// 如果是强制停止
		// 用文件名做key，记录这个文件的播放时间
		[bookmarks setObject:[dict objectForKey:kMPCPlayStoppedTimeKey] forKey:[lastPlayedPath absoluteString]];
	} else {
		// 自然关闭
		// 删除这个文件key的播放时间
		[bookmarks removeObjectForKey:[lastPlayedPath absoluteString]];
	}
	
	if ([ud boolForKey:kUDKeyAutoPlayNext] && [lastPlayedPath isFileURL] && (!stoppedByForce)) {
		//如果不是强制关闭的话
		//如果不是本地文件，肯定返回nil
		NSString *nextPath = 
			[PlayList AutoSearchNextMoviePathFrom:[lastPlayedPath path] 
										inFormats:[supportVideoFormats setByAddingObjectsFromSet:supportAudioFormats]];
		if (nextPath != nil) {
			[self loadFiles:[NSArray arrayWithObject:nextPath] fromLocal:YES];
			return;
		}
	}	
	[notifCenter postNotificationName:kMPCPlayFinalizedNotification object:self userInfo:nil];
}

////////////////////////////////////////////////cooperative actions with UI//////////////////////////////////////////////////
-(void) stop
{
	[mplayer performStop];
	// 窗口一旦关闭，清理lastPlayPath，则即使再次打开窗口也不会播放以前的文件
	SAFERELEASE(lastPlayedPath);	
}

-(void) togglePlayPause
{
	if (mplayer.state == kMPCStoppedState) {
		//mplayer不在播放状态
		if (lastPlayedPath) {
			// 有可以播放的文件
			[self playMedia:lastPlayedPath];
		}
	} else {
		// mplayer正在播放
		[mplayer togglePause];
	}
}

-(BOOL) toggleMute
{
	return (PlayerCouldAcceptCommand)? ([mplayer setMute:!mplayer.movieInfo.playingInfo.mute]):NO;
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
	if (PlayerCouldAcceptCommand && mplayer.movieInfo.seekable) {
		time = [mplayer setTimePos:time];
		[mplayer.la stop];
		return time;
	}
	return -1;
}

-(float) changeTimeBy:(float) delta
{
	// playingInfo的currentTime是通过获取log来同步的，因此这里不进行直接设定
	if (PlayerCouldAcceptCommand && mplayer.movieInfo.seekable) {
		delta = [mplayer setTimePos:[mplayer.movieInfo.playingInfo.currentTime floatValue] + delta];	
		[mplayer.la stop];
		return delta;
	}
	return -1;
}

-(float) changeSpeedBy:(float) delta
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setSpeed:[mplayer.movieInfo.playingInfo.speed floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.speed floatValue];
}

-(float) changeSubDelayBy:(float) delta
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setSubDelay:[mplayer.movieInfo.playingInfo.subDelay floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.subDelay floatValue];
}

-(float) changeAudioDelayBy:(float) delta
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setAudioDelay:[mplayer.movieInfo.playingInfo.audioDelay floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.audioDelay floatValue];	
}

-(float) changeSubScaleBy:(float) delta
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setSubScale: [mplayer.movieInfo.playingInfo.subScale floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.subScale floatValue];
}

-(float) changeSubPosBy:(float)delta
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setSubPos: mplayer.movieInfo.playingInfo.subPos + delta*100];
	}
	return mplayer.movieInfo.playingInfo.subPos;
}

-(float) changeAudioBalanceBy:(float)delta
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setBalance:mplayer.movieInfo.playingInfo.audioBalance + delta];
	}
	return mplayer.movieInfo.playingInfo.audioBalance;
}

-(float) setSpeed:(float) spd
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setSpeed:spd];
	}
	return [mplayer.movieInfo.playingInfo.speed floatValue];
}

-(float) setSubDelay:(float) sd
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setSubDelay:sd];
	}
	return [mplayer.movieInfo.playingInfo.subDelay floatValue];	
}

-(float) setAudioDelay:(float) ad
{
	if (PlayerCouldAcceptCommand) {
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

-(void) setVideo:(int) videoID
{
	[mplayer setVideo:videoID];
}

-(void) loadSubFile:(NSString*)subPath
{
	[mplayer loadSubFile:subPath];
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
	[openPanel setTitle:kMPXStringOpenMediaFiles];
	
	if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
		[self loadFiles:[openPanel URLs] fromLocal:YES];
	}
}

-(IBAction) showHelp:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[ud stringForKey:kUDKeyHelpURL]]];
}
/////////////////////////////////////Application Delegate//////////////////////////////////////
-(BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	[self loadFiles:[NSArray arrayWithObject:filename] fromLocal:YES];
	return YES;
}

-(void) application:(NSApplication *)theApplication openFiles:(NSArray *)filenames
{
	[self loadFiles:filenames fromLocal:YES];
	[theApplication replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

-(NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	[self stop];

	[ud synchronize];

	NSString *lastStoppedTimePath = [NSString stringWithFormat:kMPCFMTBookmarkPath, 
															   NSHomeDirectory(), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]];

	[openUrlController syncToBookmark:bookmarks];
	
	[bookmarks writeToFile:lastStoppedTimePath atomically:YES];
	
	return NSTerminateNow;	
}

-(void) applicationDidFinishLaunching:(NSNotification *)notification
{
	[[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}
@end
