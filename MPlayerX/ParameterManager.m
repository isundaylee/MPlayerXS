/*
 * MPlayerX - ParameterManager.m
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

#import "coredef_private.h"
#import "ParameterManager.h"
#import <UniversalDetector/UniversalDetector.h>
#import "PlayingInfo.h"

#define kPMDefaultFontPath			(@"/System/Library/Fonts/HelveticaNeue.ttc")

#define kPMDefaultSubFontPathChs	(@"/System/Library/Fonts/华文黑体.ttf")
#define kPMDefaultSubFontPathCht	(@"/System/Library/Fonts/儷黑 Pro.ttf")
#define kPMDefaultSubFontPathJpn	(@"/Library/Fonts/Osaka.ttf")

#define kPMDefaultAudioOutput		(@"coreaudio") 
#define kPMNoAudio					(@"null")
#define kPMDefaultVideoOutput		(@"corevideo") 
#define kPMNoVideo					(@"null") 
#define kPMDefaultSubLang			(@"en,eng,ch,chs,cht,ja,jpn")

#define kPMSubCPRuleExactMatchName	(0)
#define kPMSubCPRuleContainName		(1)
#define kPMSubCPRuleAnyName			(2)

#define kPMThreadsNumMax	(8)

#define SAFERELEASE(x)	if(x) {[x release]; x = nil;}

@implementation ParameterManager

@synthesize prefer64bMPlayer;
@synthesize guessSubCP;
@synthesize startTime;
@synthesize volume;
@synthesize subPos;
@synthesize subAlign;
@synthesize subScale;
@synthesize subFont;
@synthesize subCP;
@synthesize threads;

#pragma mark Init/Dealloc
-(id) init
{
	if (self = [super init])
	{
		NSNumber *haveKey = [NSNumber numberWithBool:YES];

		subFileExts = [[NSDictionary alloc] initWithObjectsAndKeys:	haveKey, @"utf", haveKey, @"utf8", 
																	haveKey, @"utf-8", haveKey, @"srt", 
																	haveKey, @"smi", haveKey, @"rt", 
																	haveKey, @"txt", haveKey, @"ssa", 
																	haveKey, @"aqt", haveKey, @"jss", 
																	haveKey, @"js", haveKey, @"ass", 
																	nil];
		subEncodeLangDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"CHS", @"GB18030",
																		 @"CHS", @"GBK",
																		 @"CHS", @"EUC-CN",
							 											 @"CHT", @"BIG5",
							 											 @"JPN", @"SHIFT_JIS",
							 											 @"JPN", @"ISO-2022-JP",
																		 nil];
		subLangDefaultSubFontDict = [[NSDictionary alloc] initWithObjectsAndKeys:kPMDefaultSubFontPathChs, @"CHS",
																				 kPMDefaultSubFontPathCht, @"CHT",
																				 kPMDefaultSubFontPathJpn, @"JPN",
																				 nil];
		autoSync = 30;
		frameDrop = YES;
		osdLevel = 0;
		subFuzziness = kPMSubCPRuleContainName;
		font = [[NSString alloc] initWithString:kPMDefaultFontPath]; // Everyone Should have this font
		ao = [[NSString alloc] initWithString:kPMDefaultAudioOutput];
		vo = [[NSString alloc] initWithString:kPMDefaultVideoOutput];
		subPreferedLanguage = [[NSString alloc] initWithString:kPMDefaultSubLang];
		ass.enabled = YES;
		ass.frontColor = 0xFFFFFF00; //RRGGBBAA
		ass.fontScale = 1.5;
		ass.borderColor = 0x00000000; //RRGGBBAA
		ass.forceStyle = [NSString stringWithString:@"BorderStyle=1,Outline=1"];

		prefer64bMPlayer = YES;
		guessSubCP = YES;
		startTime = 0.0f;
		volume = 100;
		subPos = 100;
		subAlign = 2;
		subScale = 4;
		subFont = nil;
		subCP = nil;
		threads = 1;
	}
	return self;
}

-(void) dealloc
{
	SAFERELEASE(subFileExts);
	SAFERELEASE(subEncodeLangDict);
	SAFERELEASE(subLangDefaultSubFontDict);
	SAFERELEASE(font);
	SAFERELEASE(ao);
	SAFERELEASE(vo);
	SAFERELEASE(subPreferedLanguage);
	SAFERELEASE(subFont);
	SAFERELEASE(subCP);
	[super dealloc];
}

-(void) setThreads:(unsigned int) th
{
	threads = MIN(kPMThreadsNumMax, th);
}

-(void) synchronizePlayingInfo:(PlayingInfo*) pi
{
	[pi setVolume: volume];
	[pi setSubPos: subPos];
	[pi setSubScale: [NSNumber numberWithFloat:(ass.enabled)?(ass.fontScale):subScale]];
}

-(void) disableAudio
{
	[ao release];
	ao = [[NSString alloc] initWithString:kPMNoAudio];
}

-(void) enableAudio
{
	[ao release];
	ao = [[NSString alloc] initWithString:kPMDefaultAudioOutput];
}

-(void) disableVideo
{
	[vo release];
	vo = [[NSString alloc] initWithString:kPMNoVideo];
}

-(void) enableVideo
{
	[vo release];
	vo = [[NSString alloc] initWithString:kPMDefaultVideoOutput];
}

-(NSArray *) arrayOfParametersWithName:(NSString*) name
{
	NSMutableArray *paramArray = [[NSMutableArray alloc] init];
	
	[paramArray addObject:@"-msglevel"];
	[paramArray addObject:@"all=-1:global=4:cplayer=4:identify=4"];
	
	[paramArray addObject:@"-autosync"];
	[paramArray addObject:[NSString stringWithFormat: @"%d", autoSync]];
	
	[paramArray addObject:@"-slave"];
	
	if (frameDrop) {
		[paramArray addObject:@"-framedrop"];
	}
	
	[paramArray addObject:@"-osdlevel"];
	[paramArray addObject: [NSString stringWithFormat: @"%d",osdLevel]];
	
	[paramArray addObject:@"-sub-fuzziness"];
	[paramArray addObject:[NSString stringWithFormat: @"%d",subFuzziness]];
	
	if (font) {
		[paramArray addObject:@"-font"];
		[paramArray addObject:font];
	}
	
	if (ao) {
		[paramArray addObject:@"-ao"];
		[paramArray addObject:ao];
	}
	
	if (vo) {
		[paramArray addObject:@"-vo"];
		if (([vo isEqualToString:kPMDefaultVideoOutput]) && name) {
			[paramArray addObject: [NSString stringWithFormat: @"%@:shared_buffer:buffer_name=%@", vo, name]];
		} else {
			[paramArray addObject:vo];
		}
	}
	
	if (subPreferedLanguage) {
		[paramArray addObject:@"-slang"];
		[paramArray addObject:[NSString stringWithFormat: @"%@",subPreferedLanguage]];		
	}
	
	if (((unsigned int)startTime) > 0) {
		[paramArray addObject:@"-ss"];
		[paramArray addObject:[NSString stringWithFormat: @"%.1f",startTime]];
	}
	
	[paramArray addObject:@"-volume"];
	[paramArray addObject:[NSString stringWithFormat: @"%.1f",GetRealVolume(volume)]];
	
	[paramArray addObject:@"-subpos"];
	[paramArray addObject:[NSString stringWithFormat: @"%d",subPos]];
	
	[paramArray addObject:@"-subalign"];
	[paramArray addObject:[NSString stringWithFormat: @"%d",subAlign]];
	
	[paramArray addObject:@"-subfont-osd-scale"];
	[paramArray addObject:[NSString stringWithFormat: @"%.1f",subScale]];
	
	[paramArray addObject:@"-subfont-text-scale"];
	[paramArray addObject:[NSString stringWithFormat: @"%.1f",subScale]];
	
	if (subFont && (![subFont isEqualToString:@""])) {
		[paramArray addObject:@"-subfont"];
		[paramArray addObject:subFont];
	} else {
		NSString *lang, *fontFB;
		if ((lang = [subEncodeLangDict objectForKey:subCP]) && (fontFB = [subLangDefaultSubFontDict objectForKey:lang])) {
			[paramArray addObject:@"-subfont"];
			[paramArray addObject:fontFB];
		}
	}

	if (subCP && (![subCP isEqualToString:@""])) {
		[paramArray addObject:@"-subcp"];
		[paramArray addObject:subCP];
	}
	
	if (threads >= 2) {
		[paramArray addObject:@"-lavdopts"];
		[paramArray addObject:[NSString stringWithFormat: @"threads=%d", threads]];
	}

	if (ass.enabled) {
		[paramArray addObject:@"-ass"];
		
		[paramArray addObject:@"-ass-color"];
		[paramArray addObject:[NSString stringWithFormat: @"%X", ass.frontColor]];
		
		[paramArray addObject:@"-ass-font-scale"];
		[paramArray addObject:[NSString stringWithFormat: @"%f", ass.fontScale]];
		
		[paramArray addObject:@"-ass-border-color"];
		[paramArray addObject:[NSString stringWithFormat: @"%X", ass.borderColor]];
		
		[paramArray addObject:@"-ass-force-style"];
		[paramArray addObject:[NSString stringWithFormat: @"%@", ass.forceStyle]];
	}
	return [paramArray autorelease];
}

-(NSString*) getCPFromMoviePath:(NSString*)moviePath withOptions:(unsigned long)options
{
	NSString *cpStr = nil;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	UniversalDetector *dt = [[UniversalDetector alloc] init];
	
	// 文件夹路径
	NSString *directoryPath = [moviePath stringByDeletingLastPathComponent];
	// 播放文件名称
	NSString *movieName = [[moviePath lastPathComponent] stringByDeletingPathExtension];
	
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
	
	// 遍历播放文件所在的目录
	for (NSString *path in directoryEnumerator)
	{
		NSDictionary *fileAttr = [directoryEnumerator fileAttributes];
		
		if ([fileAttr objectForKey:NSFileType] == NSFileTypeDirectory) { //不遍历子目录
			[directoryEnumerator skipDescendants];
			
		} else if(([[fileAttr objectForKey:NSFileType] isEqualToString: NSFileTypeRegular]) && [subFileExts objectForKey: [path pathExtension]]) {
			// 如果是普通的字幕文件
			switch (subFuzziness) {
				case kPMSubCPRuleExactMatchName:
					if (![movieName isEqualToString:[path stringByDeletingPathExtension]]) continue; // exact match
					break;
				case kPMSubCPRuleAnyName:
					break; // any sub file is OK
				case kPMSubCPRuleContainName:
					if ([path rangeOfString: movieName].location == NSNotFound) continue; // contain the movieName
				default:
					break;
			}
			
			[dt analyzeContentsOfFile: [NSString stringWithFormat:@"%@/%@", directoryPath, path]];
			
			if ([dt confidence] >= 0.5) {
				cpStr = [[NSString alloc] initWithString: [[dt MIMECharset] uppercaseString]];
				break;
			}
		}
	}
	[dt release];
	[pool release];
	
	if ((options & kParameterManagerSetSubCPIfGuessedOut) && cpStr) {
		[self setSubCP:cpStr];
	}
	return [cpStr autorelease];	
}

@end
