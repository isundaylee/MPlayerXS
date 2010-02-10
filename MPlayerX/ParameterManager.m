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

#import "ParameterManager.h"

#define kPMDefaultFontPath			(@"/System/Library/Fonts/HelveticaNeue.ttc")

#define kPMDefaultAudioOutput		(@"coreaudio") 
#define kPMNoAudio					(@"null")
#define kPMDefaultVideoOutput		(@"corevideo") 
#define kPMNoVideo					(@"null") 
#define kPMDefaultSubLang			(@"en,eng,ch,chs,cht,ja,jpn")

#define SAFERELEASE(x)	if(x) {[x release]; x = nil;}

@implementation ParameterManager

@synthesize subNameRule;
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
@synthesize textSubs;
@synthesize vobSub;
@synthesize forceIndex;
@synthesize dtsPass;
@synthesize ac3Pass;
@synthesize fastDecoding;
@synthesize useEmbeddedFonts;
@synthesize cache;
@synthesize preferIPV6;
@synthesize letterBoxMode;
@synthesize letterBoxHeight;

#pragma mark Init/Dealloc
-(id) init
{
	if (self = [super init])
	{
		autoSync = 30;
		frameDrop = YES;
		osdLevel = 0;
		subNameRule = kSubFileNameRuleContain;
		// 默认禁用-font
		font = nil; // [[NSString alloc] initWithString:kPMDefaultFontPath]; // Everyone Should have this font
		ao = [[NSString alloc] initWithString:kPMDefaultAudioOutput];
		vo = [[NSString alloc] initWithString:kPMDefaultVideoOutput];
		subPreferedLanguage = [[NSString alloc] initWithString:kPMDefaultSubLang];
		
		assEnabled = YES;
		frontColor = 0xFFFFFF00; //RRGGBBAA
		borderColor = 0x0000000F; //RRGGBBAA
		assForceStyle = [NSString stringWithString:@"BorderStyle=1,Outline=1"];
		
		prefer64bMPlayer = YES;
		guessSubCP = YES;
		startTime = -1;
		volume = 100;
		subPos = 100;
		subAlign = 2;
		subScale = 4;
		subFont = nil;
		subCP = nil;
		threads = 1;
		textSubs = nil;
		vobSub = nil;
		forceIndex = NO;
		dtsPass = NO;
		ac3Pass = NO;
		fastDecoding = NO;
		useEmbeddedFonts = NO;
		cache = 1000;
		preferIPV6 = NO;
		letterBoxMode = kPMLetterBoxModeNotDisplay;
		letterBoxHeight = 0.1;
	}
	return self;
}

-(void) dealloc
{
	[font release];
	[ao release];
	[vo release];
	[subPreferedLanguage release];
	[subFont release];
	[subCP release];
	[textSubs release];
	[vobSub release];
	
	[super dealloc];
}

-(void) setSubFontColor:(NSColor*)col
{
	col = [col colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	frontColor = (((uint32)(255 * [col redComponent]))  <<24) + 
				 (((uint32)(255 * [col greenComponent]))<<16) + 
				 (((uint32)(255 * [col blueComponent])) <<8)  +
				  ((uint32)(255 * (1-[col alphaComponent])));
}

-(void) setSubFontBorderColor:(NSColor*)col
{
	col = [col colorUsingColorSpaceName:NSCalibratedRGBColorSpace];	
	borderColor = (((uint32)(255 * [col redComponent]))  <<24) + 
				  (((uint32)(255 * [col greenComponent]))<<16) + 
				  (((uint32)(255 * [col blueComponent])) <<8) + 
				   ((uint32)(255 * (1-[col alphaComponent])));
	
}

-(void) reset
{
	SAFERELEASE(vobSub);
	SAFERELEASE(textSubs);
}

-(NSArray *) arrayOfParametersWithName:(NSString*) name
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray *paramArray = [[NSMutableArray alloc] initWithCapacity:80];
	
	[paramArray addObject:@"-msglevel"];
	[paramArray addObject:@"all=-1:global=4:cplayer=4:identify=4"];
	
	[paramArray addObject:@"-autosync"];
	[paramArray addObject:[NSString stringWithFormat: @"%d", autoSync]];
	
	[paramArray addObject:@"-slave"];
	
	if (frameDrop) {
		[paramArray addObject:@"-framedrop"];
	}
	
	if (forceIndex) {
		[paramArray addObject:@"-forceidx"];
	}

	[paramArray addObject:@"-nodouble"];
	
	if (cache > 0) {
		[paramArray addObject:@"-cache"];
		[paramArray addObject:[NSString stringWithFormat:@"%d", cache]];
	}
	
	if (preferIPV6) {
		[paramArray addObject:@"-prefer-ipv6"];
	} else {
		[paramArray addObject:@"-prefer-ipv4"];
	}
	
	[paramArray addObject:@"-osdlevel"];
	[paramArray addObject: [NSString stringWithFormat: @"%d",osdLevel]];
	
	[paramArray addObject:@"-sub-fuzziness"];
	[paramArray addObject:[NSString stringWithFormat: @"%d",subNameRule]];
	
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
	
	if (startTime > 0) {
		[paramArray addObject:@"-ss"];
		[paramArray addObject:[NSString stringWithFormat: @"%.1f",startTime]];
	}
	
	[paramArray addObject:@"-volume"];
	[paramArray addObject:[NSString stringWithFormat: @"%.1f",GetRealVolume(volume)]];
	
	[paramArray addObject:@"-subpos"];
	[paramArray addObject:[NSString stringWithFormat: @"%d",((unsigned int)subPos)]];
	
	[paramArray addObject:@"-subalign"];
	[paramArray addObject:[NSString stringWithFormat: @"%d",subAlign]];
	
	[paramArray addObject:@"-subfont-osd-scale"];
	[paramArray addObject:[NSString stringWithFormat: @"%.1f",subScale]];
	
	[paramArray addObject:@"-subfont-text-scale"];
	[paramArray addObject:[NSString stringWithFormat: @"%.1f",subScale]];
	
	if (subFont && (![subFont isEqualToString:@""])) {
		[paramArray addObject:@"-subfont"];
		[paramArray addObject:subFont];
	}

	if (subCP && (![subCP isEqualToString:@""])) {
		[paramArray addObject:@"-subcp"];
		[paramArray addObject:subCP];
	}
	
	// 字幕大小与高度成正比，默认是对角线长度
	[paramArray addObject:@"-subfont-autoscale"];
	[paramArray addObject:@"1"];
	
	if (useEmbeddedFonts) {
		[paramArray addObject:@"-embeddedfonts"];
	}
		
	[paramArray addObject:@"-lavdopts"];
	NSString *str = [NSString stringWithFormat: @"threads=%d", threads];
	if (fastDecoding) {
		str = [str stringByAppendingString:@":fast:skiploopfilter=all"];
	}
	[paramArray addObject:str];

	if (assEnabled) {
		[paramArray addObject:@"-ass"];
		
		[paramArray addObject:@"-ass-color"];
		[paramArray addObject:[NSString stringWithFormat: @"%X", frontColor]];
		
		[paramArray addObject:@"-ass-font-scale"];
		[paramArray addObject:[NSString stringWithFormat: @"%.1f", subScale]];
		
		[paramArray addObject:@"-ass-border-color"];
		[paramArray addObject:[NSString stringWithFormat: @"%X", borderColor]];
		
		[paramArray addObject:@"-ass-force-style"];
		[paramArray addObject:assForceStyle];
		
		// 目前只有在使用ass的时候，letterbox才有用
		// 但是将来也许不用ass也要实现letter box
		if (letterBoxMode != kPMLetterBoxModeNotDisplay) {
			// 说明要显示letterBox，那么至少会显示bottom
			// 字幕显示在letterBox里
			[paramArray addObject:@"-ass-use-margins"];
			
			[paramArray addObject:@"-ass-bottom-margin"];
			[paramArray addObject:[NSString stringWithFormat: @"%.2f", letterBoxHeight]];
			
			if (letterBoxMode == kPMLetterBoxModeBoth) {
				// 还要显示top margin
				[paramArray addObject:@"-ass-top-margin"];
				[paramArray addObject:[NSString stringWithFormat: @"%.2f", letterBoxHeight]];
			}
		}
	}
	
	if (guessSubCP) {
		[paramArray addObject:@"-noautosub"];
	}

	if (textSubs && [textSubs count]) {
		[paramArray addObject:@"-sub"];	
		[paramArray addObject:[textSubs componentsJoinedByString:@","]];
	}
	
	if (vobSub && (![vobSub isEqualToString:@""])) {
		[paramArray addObject:@"-vobsub"];
		[paramArray addObject:[vobSub stringByDeletingPathExtension]];
	}

	if (dtsPass || ac3Pass) {
		[paramArray addObject:@"-ac"];
		NSString *passStr = @"";
		if (dtsPass) {
			passStr = [passStr stringByAppendingString:@"hwdts,"];
		}
		if (ac3Pass) {
			passStr = [passStr stringByAppendingString:@"hwac3,a52,"];
		}
		[paramArray addObject:passStr];
	}

	[pool release];
	
	return [paramArray autorelease];
}

@end
