/*
 * MPlayerX - AppController.m
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

#import "AppController.h"
#import "UserDefaults.h"
#import "CocoaAppendix.h"
#import <Sparkle/Sparkle.h>
#import "PlayerController.h"
#import "OpenURLController.h"
#import "LocalizedStrings.h"

NSString * const kMPCFMTBookmarkPath	= @"%@/Library/Preferences/%@.bookmarks.plist";

static AppController *sharedInstance = nil;
static BOOL init_ed = NO;

@implementation AppController

@synthesize bookmarks;
@synthesize supportVideoFormats;
@synthesize supportAudioFormats;
@synthesize supportSubFormats;

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   @"http://mplayerx.googlecode.com/svn/trunk/update/appcast.xml", @"SUFeedURL",
					   @"http://code.google.com/p/mplayerx/wiki/Help?tm=6", kUDKeyHelpURL,
					   nil]];

	MPSetLogEnable([[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyLogMode]);
}
					   
+(AppController*) sharedAppController
{
	if (sharedInstance == nil) {
		sharedInstance = [[super allocWithZone:nil] init];
	}
	return sharedInstance;
}

-(id) init
{
	if (init_ed == NO) {
		init_ed = YES;

		ud = [NSUserDefaults standardUserDefaults];
		notifCenter = [NSNotificationCenter defaultCenter];
		
		/////////////////////////setup auto update////////////////////
		// 设定手动更新
		[[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:NO];
		
		NSBundle *mainBundle = [NSBundle mainBundle];
		// 建立支持格式的Set
		for( NSDictionary *dict in [mainBundle objectForInfoDictionaryKey:CFBundleDocumentTypes]) {
			
			NSString *obj = [dict objectForKey:CFBundleTypeName];
			// 对不同种类的格式
			if ([obj isEqualToString:@"Audio Media"]) {
				// 如果是音频文件
				supportAudioFormats = [[NSSet alloc] initWithArray:[dict objectForKey:CFBundleTypeExtensions]];
				
			} else if ([obj isEqualToString:@"Video Media"]) {
				// 如果是视频文件
				supportVideoFormats = [[NSSet alloc] initWithArray:[dict objectForKey:CFBundleTypeExtensions]];
			} else if ([obj isEqualToString:@"Subtitle"]) {
				// 如果是字幕文件
				supportSubFormats = [[NSSet alloc] initWithArray:[dict objectForKey:CFBundleTypeExtensions]];
			}
		}
		
		/////////////////////////setup bookmarks////////////////////
		// 得到书签的文件名
		NSString *lastStoppedTimePath = [NSString stringWithFormat:kMPCFMTBookmarkPath, 
										 NSHomeDirectory(), [mainBundle objectForInfoDictionaryKey:CFBundleIdentifier]];
		// 得到记录播放时间的dict
		bookmarks = [[NSMutableDictionary alloc] initWithContentsOfFile:lastStoppedTimePath];
		if (!bookmarks) {
			// 如果文件不存在或者格式非法
			bookmarks = [[NSMutableDictionary alloc] initWithCapacity:10];
		}		
	}
	return self;
}

+(id) allocWithZone:(NSZone *)zone { return [[self sharedAppController] retain]; }
-(id) copyWithZone:(NSZone*)zone { return self; }
-(id) retain { return self; }
-(NSUInteger) retainCount { return NSUIntegerMax; }
-(void) release { }
-(id) autorelease { return self; }

-(void) dealloc
{
	sharedInstance = nil;
	
	[supportVideoFormats release];
	[supportAudioFormats release];
	[supportSubFormats release];
	
	[bookmarks release];
	
	[super dealloc];
}

-(void) awakeFromNib
{
	NSBundle *mainBundle = [NSBundle mainBundle];

	// setup version info
	[aboutText setStringValue:[NSString stringWithFormat: @"MPlayerX %@ (r%@) by Zongyao QU@2009,2010", 
							   [mainBundle objectForInfoDictionaryKey:CFBundleShortVersionString],
							   [mainBundle objectForInfoDictionaryKey:CFBundleVersion]]];

	// setup url list for OpenURL Panel
	[openUrlController initURLList:bookmarks];

	// setup sleep timer
	NSTimer *prevSlpTimer = [NSTimer timerWithTimeInterval:20
													target:playerController
												  selector:@selector(preventSystemSleep)
												  userInfo:nil
												   repeats:YES];
	NSRunLoop *rl = [NSRunLoop mainRunLoop];
	[rl addTimer:prevSlpTimer forMode:NSDefaultRunLoopMode];
	[rl addTimer:prevSlpTimer forMode:NSModalPanelRunLoopMode];
	[rl addTimer:prevSlpTimer forMode:NSEventTrackingRunLoopMode];	
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
		[playerController loadFiles:[openPanel URLs] fromLocal:YES];
	}
}

-(IBAction) showHelp:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[ud stringForKey:kUDKeyHelpURL]]];
}
/////////////////////////////////////Application Delegate//////////////////////////////////////
-(BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	[playerController loadFiles:[NSArray arrayWithObject:filename] fromLocal:YES];
	return YES;
}

-(void) application:(NSApplication *)theApplication openFiles:(NSArray *)filenames
{
	[playerController loadFiles:filenames fromLocal:YES];
	[theApplication replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

-(NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	[playerController stop];
	
	[ud synchronize];
	
	NSString *lastStoppedTimePath = [NSString stringWithFormat:kMPCFMTBookmarkPath, 
									 NSHomeDirectory(), [[NSBundle mainBundle] objectForInfoDictionaryKey:CFBundleIdentifier]];
	
	[openUrlController syncToBookmark:bookmarks];
	
	[bookmarks writeToFile:lastStoppedTimePath atomically:YES];
	
	return NSTerminateNow;	
}

-(void) applicationDidFinishLaunching:(NSNotification *)notification
{
	[[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}

@end
