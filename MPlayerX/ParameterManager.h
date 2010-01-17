/*
 * MPlayerX - ParameterManager.h
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
#import "coredef_private.h"

typedef struct
{
	BOOL enabled;
	uint32 frontColor;
	float fontScale;
	uint32 borderColor;
	NSString *forceStyle;
} ASS_SETTINGS;

@interface ParameterManager : NSObject 
{
	unsigned char autoSync;
	BOOL frameDrop;
	unsigned char osdLevel;
	SUBFILE_NAMERULE subNameRule;
	NSString *font;
	NSString *ao;
	NSString *vo;
	NSString *subPreferedLanguage;
	ASS_SETTINGS ass;
	unsigned int cache;
	
	// accessable variables
	BOOL prefer64bMPlayer;
	BOOL guessSubCP;
	float startTime;
	float volume;
	float subPos;
	unsigned char subAlign;
	float subScale;
	NSString *subFont;
	NSString *subCP;
	unsigned int threads;
	NSArray *textSubs;
	NSString *vobSub;
	BOOL forceIndex;
	BOOL dtsPass;
	BOOL ac3Pass;
	BOOL fastDecoding;
}

@property (assign, readwrite) SUBFILE_NAMERULE subNameRule;
@property (assign, readwrite) BOOL prefer64bMPlayer;
@property (assign, readwrite) BOOL guessSubCP;
@property (assign, readwrite) float startTime;
@property (assign, readwrite) float volume;
@property (assign, readwrite) float subPos;
@property (assign, readwrite) unsigned char subAlign;
@property (assign, readwrite) float subScale;
@property (retain, readwrite) NSString *subFont;
@property (retain, readwrite) NSString *subCP;
@property (assign, readwrite) unsigned int threads;
@property (retain, readwrite) NSArray *textSubs;
@property (retain, readwrite) NSString *vobSub;
@property (assign, readwrite) BOOL forceIndex;
@property (assign, readwrite) BOOL dtsPass;
@property (assign, readwrite) BOOL ac3Pass;
@property (assign, readwrite) BOOL fastDecoding;

// 这个接口是面向playingInfo
-(float) subScaleInternal;
-(void) setSubFontColor:(NSColor*)col;
-(void) setSubFontBorderColor:(NSColor*)col;

-(NSArray *) arrayOfParametersWithName:(NSString*) name;

-(void) reset;

@end
