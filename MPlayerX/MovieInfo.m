/*
 * MPlayerX - MovieInfo.m
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

#import "MovieInfo.h"
#import "coredef_private.h"

@interface MovieInfo (LogAnalyzerDelegate)
-(void) logAnalyzeFinished:(NSDictionary*) dict;
@end


#define kMITypeFloat	(1)
#define kMITypeBool		(2)
#define kMITypeSubArray	(3)

@implementation MovieInfo

@synthesize demuxer;
@synthesize chapters;
@synthesize length;
@synthesize seekable;

@synthesize playingInfo;

@synthesize metaData;

@synthesize videoInfo;
@synthesize audioInfo;
@synthesize subInfo;

-(id) init
{
	if (self = [super init])
	{
		keyPathDict = [[NSDictionary alloc] initWithObjectsAndKeys:kKVOPropertyKeyPathCurrentTime, kMPCTimePos, 
																   kKVOPropertyKeyPathLength, kMPCLengthID,
																   kKVOPropertyKeyPathSeekable, kMPCSeekableID,
																   kKVOPropertyKeyPathSubInfo, kMPCSubInfosID,
																   nil];
		typeDict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:kMITypeFloat], kMPCTimePos, 
																[NSNumber numberWithInt:kMITypeFloat], kMPCLengthID,
																[NSNumber numberWithInt:kMITypeBool], kMPCSeekableID,
																[NSNumber numberWithInt:kMITypeSubArray], kMPCSubInfosID,
																nil];
		demuxer = nil;
		chapters = nil;
		length = nil;
		seekable = NO;
		
		playingInfo = [[PlayingInfo alloc] init];
		metaData = [[NSMutableDictionary alloc] init];
		videoInfo = [[NSMutableArray alloc] init];
		audioInfo = [[NSMutableArray alloc] init];
		subInfo = nil;
	}
	return self;
}

-(void) dealloc
{
	[demuxer release];
	[chapters release];
	[length release];
	[playingInfo release];
	[metaData release];
	[videoInfo release];
	[audioInfo release];
	[subInfo release];
	[super dealloc];
}

-(void) reset
{
	[playingInfo reset];
	[metaData removeAllObjects];
	[videoInfo removeAllObjects];
	[audioInfo removeAllObjects];

	[demuxer release];
	[chapters release];
	
	[self setSeekable:NO];
	demuxer = nil;
	chapters = nil;
	[self setLength:nil];
	[self setSubInfo:nil];
}

// 这个是LogAnalyzer的delegate方法，
// 因此是运行在工作线程上的，因为这里用到了KVC和KVO
// 有没有必要运行在主线程上？
-(void) logAnalyzeFinished:(NSDictionary*) dict
{
	for (NSString *key in dict) {
		NSString *keyPath = [keyPathDict objectForKey:key];

		if (keyPath) {
			//如果log里面能找到相应的key path
			switch ([[typeDict objectForKey:key] intValue]) {
				case kMITypeFloat:
					[self setValue:[NSNumber numberWithFloat:[[dict objectForKey:key] floatValue]] forKeyPath:keyPath];
					break;
				case kMITypeBool:
					[self setValue:[NSNumber numberWithBool:[[dict objectForKey:key] boolValue]] forKeyPath:keyPath];
					break;
				case kMITypeSubArray:
					[self setValue:[[dict objectForKey:key] componentsSeparatedByString:@":"] forKeyPath:keyPath];
					break;

				default:
					break;
			}
		}
	}
}
@end
