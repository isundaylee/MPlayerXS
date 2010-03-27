/*
 * MPlayerX - ParameterManager.m
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

#import "ParameterManager.h"
#import "CocoaAppendix.h"

NSString * const kPMDefaultFontPath = @"/System/Library/Fonts/HelveticaNeue.ttc";

NSString * const kPMDefaultAudioOutput	= @"coreaudio"; 
NSString * const kPMNoAudio				= @"null";
NSString * const kPMDefaultVideoOutput	= @"corevideo"; 
NSString * const kPMNoVideo				= @"null";
NSString * const kPMDefaultSubLang		= @"en,eng,ch,chs,cht,ja,jpn";

NSString * const kPMParMsgLevel		= @"-msglevel";
NSString * const kPMValMsgLevel		= @"all=-1:global=4:cplayer=4:identify=4";
NSString * const kPMParAutoSync		= @"-autosync";
NSString * const kPMFMTInt			= @"%d";
NSString * const kPMParSlave		= @"-slave";
NSString * const kPMParFrameDrop	= @"-framedrop";
NSString * const kPMParForceIdx		= @"-forceidx";
NSString * const kPMParNoDouble		= @"-nodouble";
NSString * const kPMParCache		= @"-cache";
NSString * const kPMParIPV6			= @"-prefer-ipv6";
NSString * const kPMParIPV4			= @"-prefer-ipv4";
NSString * const kPMParOsdLevel		= @"-osdlevel";
NSString * const kPMParSubFuzziness	= @"-sub-fuzziness";
NSString * const kPMParFont			= @"-font";
NSString * const kPMParAudioOut		= @"-ao";
NSString * const kPMParVideoOut		= @"-vo";
NSString * const kPMFMTVO			= @"%@:shared_buffer:buffer_name=%@";
NSString * const kPMParSLang		= @"-slang";
NSString * const kPMFMTNSObj		= @"%@";
NSString * const kPMParStartTime	= @"-ss";
NSString * const kPMFMTFloat1		= @"%.1f";
NSString * const kPMParVolume		= @"-volume";
NSString * const kPMFMTFloat2		= @"%.2f";
NSString * const kPMFMTHex			= @"%X";
NSString * const kPMParSubPos		= @"-subpos";
NSString * const kPMParSubAlign		= @"-subalign";
NSString * const kPMParOSDScale		= @"-subfont-osd-scale";
NSString * const kPMParTextScale	= @"-subfont-text-scale";
NSString * const kPMBlank			= @"";
NSString * const kPMParSubFont		= @"-subfont";
NSString * const kPMParSubCP		= @"-subcp";
NSString * const kPMParSubFontAutoScale	= @"-subfont-autoscale";
NSString * const kPMVal1				= @"1";
NSString * const kPMParEmbeddedFonts	= @"-embeddedfonts";
NSString * const kPMParLavdopts			= @"-lavdopts";
NSString * const kPMFMTThreads			= @"threads=%d";
NSString * const kPMParAss				= @"-ass";
NSString * const kPMParAssColor			= @"-ass-color";
NSString * const kPMParAssFontScale		= @"-ass-font-scale";
NSString * const kPMParAssBorderColor	= @"-ass-border-color";
NSString * const kPMParAssForcrStyle	= @"-ass-force-style";
NSString * const kPMParAssUsesMargin	= @"-ass-use-margins";
NSString * const kPMParAssBottomMargin	= @"-ass-bottom-margin";
NSString * const kPMParAssTopMargin		= @"-ass-top-margin";
NSString * const kPMParNoAutoSub		= @"-noautosub";
NSString * const kPMParSub				= @"-sub";
NSString * const kPMComma				= @",";
NSString * const kPMParVobSub			= @"-vobsub";
NSString * const kPMParAC				= @"-ac";
NSString * const kPMParHWDTS			= @"hwdts,";
NSString * const kPMParHWAC3			= @"hwac3,a52,";
NSString * const kPMParSTPause			= @"-stpause";
NSString * const kPMParDemuxer			= @"-demuxer";
NSString * const kPMValDemuxLavf		= @"lavf";

#define SAFERELEASE(x)	if(x) {[x release]; x = nil;}

#define kSubScaleNoAss		(4.0)

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
@synthesize useEmbeddedFonts;
@synthesize cache;
@synthesize preferIPV6;
@synthesize letterBoxMode;
@synthesize letterBoxHeight;
@synthesize pauseAtStart;

#pragma mark Init/Dealloc
-(id) init
{
	if (self = [super init])
	{
		paramArray = nil;
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
		assForceStyle = [NSString stringWithString:@"BorderStyle=1,Outline=1,Fontsize=12,MarginV=2"];
		
		prefer64bMPlayer = YES;
		guessSubCP = YES;
		startTime = -1;
		volume = 100;
		subPos = 100;
		subAlign = 2;
		subScale = 1.5;
		subFont = nil;
		subCP = nil;
		threads = 1;
		textSubs = nil;
		vobSub = nil;
		forceIndex = NO;
		dtsPass = NO;
		ac3Pass = NO;
		useEmbeddedFonts = NO;
		cache = 1000;
		preferIPV6 = NO;
		letterBoxMode = kPMLetterBoxModeNotDisplay;
		letterBoxHeight = 0.1;
		pauseAtStart = NO;
	}
	return self;
}

-(void) dealloc
{
	[paramArray release];
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
	frontColor = [col convertToHex];
}

-(void) setSubFontBorderColor:(NSColor*)col
{
	borderColor = [col convertToHex];
}

-(void) reset
{
	SAFERELEASE(vobSub);
	SAFERELEASE(textSubs);
}

-(NSArray *) arrayOfParametersWithName:(NSString*) name
{
	if (paramArray) {
		[paramArray removeAllObjects];
	} else {
		paramArray = [[NSMutableArray alloc] initWithCapacity:80];
	}
	
	// [paramArray addObject:kPMParDemuxer];
	// [paramArray addObject:kPMValDemuxLavf];
	
	[paramArray addObject:kPMParMsgLevel];
	[paramArray addObject:kPMValMsgLevel];
	
	[paramArray addObject:kPMParAutoSync];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTInt, autoSync]];
	
	[paramArray addObject:kPMParSlave];
	
	if (frameDrop) {
		[paramArray addObject:kPMParFrameDrop];
	}
	
	if (forceIndex) {
		[paramArray addObject:kPMParForceIdx];
	}

	[paramArray addObject:kPMParNoDouble];
	
	if (cache > 0) {
		[paramArray addObject:kPMParCache];
		[paramArray addObject:[NSString stringWithFormat:kPMFMTInt, cache]];
	}
	
	if (preferIPV6) {
		[paramArray addObject:kPMParIPV6];
	} else {
		[paramArray addObject:kPMParIPV4];
	}
	
	[paramArray addObject:kPMParOsdLevel];
	[paramArray addObject: [NSString stringWithFormat: kPMFMTInt,osdLevel]];
	
	[paramArray addObject:kPMParSubFuzziness];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTInt,subNameRule]];
	
	if (font) {
		[paramArray addObject:kPMParFont];
		[paramArray addObject:font];
	}
	
	if (ao) {
		[paramArray addObject:kPMParAudioOut];
		[paramArray addObject:ao];
	}
	
	if (vo) {
		[paramArray addObject:kPMParVideoOut];
		if (([vo isEqualToString:kPMDefaultVideoOutput]) && name) {
			[paramArray addObject: [NSString stringWithFormat:kPMFMTVO, vo, name]];
		} else {
			[paramArray addObject:vo];
		}
	}
	
	if (subPreferedLanguage) {
		[paramArray addObject:kPMParSLang];
		[paramArray addObject:[NSString stringWithFormat:kPMFMTNSObj, subPreferedLanguage]];		
	}
	
	if (startTime > 0) {
		[paramArray addObject:kPMParStartTime];
		[paramArray addObject:[NSString stringWithFormat:kPMFMTFloat1, startTime]];
	}
	
	[paramArray addObject:kPMParVolume];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTFloat1,GetRealVolume(volume)]];
	
	[paramArray addObject:kPMParSubPos];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTInt,((unsigned int)subPos)]];
	
	[paramArray addObject:kPMParSubAlign];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTInt,subAlign]];
	
	[paramArray addObject:kPMParOSDScale];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTFloat1,kSubScaleNoAss]];
	
	[paramArray addObject:kPMParTextScale];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTFloat1,kSubScaleNoAss]];
	
	if (subFont && (![subFont isEqualToString:kPMBlank])) {
		[paramArray addObject:kPMParSubFont];
		[paramArray addObject:subFont];
	}

	if (subCP && (![subCP isEqualToString:kPMBlank])) {
		[paramArray addObject:kPMParSubCP];
		[paramArray addObject:subCP];
	}
	
	// 字幕大小与高度成正比，默认是对角线长度
	[paramArray addObject:kPMParSubFontAutoScale];
	[paramArray addObject:kPMVal1];
	
	if (useEmbeddedFonts) {
		[paramArray addObject:kPMParEmbeddedFonts];
	}
		
	[paramArray addObject:kPMParLavdopts];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTThreads, threads]];

	if (assEnabled) {
		[paramArray addObject:kPMParAss];
		
		[paramArray addObject:kPMParAssColor];
		[paramArray addObject:[NSString stringWithFormat: kPMFMTHex, frontColor]];
		
		[paramArray addObject:kPMParAssFontScale];
		[paramArray addObject:[NSString stringWithFormat: kPMFMTFloat1, subScale]];
		
		[paramArray addObject:kPMParAssBorderColor];
		[paramArray addObject:[NSString stringWithFormat: kPMFMTHex, borderColor]];
		
		[paramArray addObject:kPMParAssForcrStyle];
		[paramArray addObject:assForceStyle];
		
		// 目前只有在使用ass的时候，letterbox才有用
		// 但是将来也许不用ass也要实现letter box
		if (letterBoxMode != kPMLetterBoxModeNotDisplay) {
			// 说明要显示letterBox，那么至少会显示bottom
			// 字幕显示在letterBox里
			[paramArray addObject:kPMParAssUsesMargin];
			
			[paramArray addObject:kPMParAssBottomMargin];
			[paramArray addObject:[NSString stringWithFormat:kPMFMTFloat2, letterBoxHeight]];
			
			if (letterBoxMode == kPMLetterBoxModeBoth) {
				// 还要显示top margin
				[paramArray addObject:kPMParAssTopMargin];
				[paramArray addObject:[NSString stringWithFormat: kPMFMTFloat2, letterBoxHeight]];
			}
		}
	}
	
	if (guessSubCP) {
		[paramArray addObject:kPMParNoAutoSub];
	}

	if (textSubs && [textSubs count]) {
		[paramArray addObject:kPMParSub];	
		[paramArray addObject:[textSubs componentsJoinedByString:kPMComma]];
	}
	
	if (vobSub && (![vobSub isEqualToString:kPMBlank])) {
		[paramArray addObject:kPMParVobSub];
		[paramArray addObject:[vobSub stringByDeletingPathExtension]];
	}

	if (dtsPass || ac3Pass) {
		[paramArray addObject:kPMParAC];
		NSString *passStr = kPMBlank;
		if (dtsPass) {
			passStr = [passStr stringByAppendingString:kPMParHWDTS];
		}
		if (ac3Pass) {
			passStr = [passStr stringByAppendingString:kPMParHWAC3];
		}
		[paramArray addObject:passStr];
	}
	
	if (pauseAtStart) {
		[paramArray addObject:kPMParSTPause];
	}
	
	return paramArray;
}

@end
