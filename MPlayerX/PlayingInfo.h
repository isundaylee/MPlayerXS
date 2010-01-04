/*
 * MPlayerX - PlayingInfo.h
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

@interface PlayingInfo : NSObject 
{
	unsigned char	currentChapter;
	NSNumber		*currentTime;
	unsigned char	currentAudio;
	unsigned char	currentVideo;
	unsigned char	currentSub;
	
	float volume;
	float audioBalance;
	BOOL  mute;
	NSNumber *audioDelay;
	NSNumber *subDelay;
	unsigned char subPos;
	BOOL subVisibility;
	NSNumber *subScale;
	NSNumber *speed;
}

@property(assign, readwrite) unsigned char	currentChapter;
@property(retain, readwrite) NSNumber		*currentTime;
@property(assign, readwrite) unsigned char	currentAudio;
@property(assign, readwrite) unsigned char	currentVideo;
@property(assign, readwrite) unsigned char	currentSub;

@property(assign, readwrite) float volume;
@property(assign, readwrite) float audioBalance;
@property(assign, readwrite) BOOL  mute;
@property(retain, readwrite) NSNumber *audioDelay;
@property(retain, readwrite) NSNumber *subDelay;
@property(assign, readwrite) unsigned char subPos;
@property(assign, readwrite) BOOL subVisibility;
@property(retain, readwrite) NSNumber * subScale;
@property(retain, readwrite) NSNumber *speed;
-(void) reset;

@end
