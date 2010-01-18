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

#pragma mark Init/Dealloc
-(id) init
{
	if (self = [super init])
	{
		autoSync = 30;
		frameDrop = YES;
		osdLevel = 0;
		subNameRule = kSubFileNameRuleContain;
		font = [[NSString alloc] initWithString:kPMDefaultFontPath]; // Everyone Should have this font
		ao = [[NSString alloc] initWithString:kPMDefaultAudioOutput];
		vo = [[NSString alloc] initWithString:kPMDefaultVideoOutput];
		subPreferedLanguage = [[NSString alloc] initWithString:kPMDefaultSubLang];
		
		ass.enabled = YES;
		ass.frontColor = 0xFFFFFF00; //RRGGBBAA
		ass.fontScale = 1.5;
		ass.borderColor = 0x0000000F; //RRGGBBAA
		ass.forceStyle = [NSString stringWithString:@"BorderStyle=1,Outline=1"];
		
		cache = 1000;

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

-(float) subScaleInternal
{
	return (ass.enabled)?ass.fontScale:subScale;
}

-(void) setSubFontColor:(NSColor*)col
{
	col = [col colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	ass.frontColor = (((uint32)(255 * [col redComponent]))  <<24) + 
					 (((uint32)(255 * [col greenComponent]))<<16) + 
					 (((uint32)(255 * [col blueComponent])) <<8)  +
					  ((uint32)(255 * (1-[col alphaComponent])));
}

-(void) setSubFontBorderColor:(NSColor*)col
{
	col = [col colorUsingColorSpaceName:NSCalibratedRGBColorSpace];	
	ass.borderColor = (((uint32)(255 * [col redComponent]))  <<24) + 
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
	
	if (useEmbeddedFonts) {
		[paramArray addObject:@"-embeddedfonts"];
	}
		
	[paramArray addObject:@"-lavdopts"];
	NSString *str = [NSString stringWithFormat: @"threads=%d", threads];
	if (fastDecoding) {
		str = [str stringByAppendingString:@":fast:skiploopfilter=all"];
	}
	[paramArray addObject:str];

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
	
	if (textSubs && [textSubs count]) {
		[paramArray addObject:@"-noautosub"];
		[paramArray addObject:@"-sub"];	
		[paramArray addObject:[textSubs componentsJoinedByString:@","]];
	}
	
	if (vobSub && (![vobSub isEqualToString:@""])) {
		[paramArray addObject:@"-vobsub"];
		[paramArray addObject:vobSub];
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
