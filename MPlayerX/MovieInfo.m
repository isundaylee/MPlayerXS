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
#import "ParameterManager.h"

@interface MovieInfo (LogAnalyzerDelegate)
-(void) logAnalyzeFinished:(NSDictionary*) dict;
@end


#define kMITypeFloat		(1)
#define kMITypeBool			(2)
#define kMITypeSubArray		(3)
#define kMITypeSubAppend	(4)

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
																   kKVOPropertyKeyPathSubInfo, kMPCSubInfoAppendID,
																   nil];
		typeDict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:kMITypeFloat], kMPCTimePos, 
																[NSNumber numberWithInt:kMITypeFloat], kMPCLengthID,
																[NSNumber numberWithInt:kMITypeBool], kMPCSeekableID,
																[NSNumber numberWithInt:kMITypeSubArray], kMPCSubInfosID,
																[NSNumber numberWithInt:kMITypeSubAppend], kMPCSubInfoAppendID,
																nil];
		demuxer = nil;
		chapters = nil;
		length = nil;
		seekable = NO;
		
		playingInfo = [[PlayingInfo alloc] init];
		metaData = [[NSMutableDictionary alloc] init];
		videoInfo = [[NSMutableArray alloc] init];
		audioInfo = [[NSMutableArray alloc] init];
		subInfo = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void) dealloc
{
	[keyPathDict release];
	[typeDict release];

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

-(void) resetWithParameterManager:(ParameterManager*)pm
{
	if (pm) {
		[playingInfo resetWithParameterManager:pm];
	}
	[metaData removeAllObjects];
	[videoInfo removeAllObjects];
	[audioInfo removeAllObjects];

	[self setSeekable:NO];
	[self setDemuxer:nil];
	[self setChapters:nil];
	[self setLength:nil];
	
	[self willChangeValueForKey:@"subInfo"];
	[subInfo removeAllObjects];
	[self didChangeValueForKey:@"subInfo"];
}

// 这个是LogAnalyzer的delegate方法，
// 因此是运行在工作线程上的，因为这里用到了KVC和KVO
// 有没有必要运行在主线程上？
-(void) logAnalyzeFinished:(NSDictionary*) dict
{
	for (NSString *key in dict) {
		NSString *keyPath = [keyPathDict objectForKey:key];
		id obj;
		
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
					// 这里如果直接使用KVO的话，产生的时Insert的change，效率太低
					// 因此手动发生KVO
					[self willChangeValueForKey:@"subInfo"];
					[subInfo setArray:[[dict objectForKey:key] componentsSeparatedByString:@":"]];
					[self didChangeValueForKey:@"subInfo"];					
					break;
				case kMITypeSubAppend:
					// 会发生insert的KVO change
					obj = [[dict objectForKey:key] componentsSeparatedByString:@":"];
					// NSLog(@"%@", obj);
					[[self mutableArrayValueForKey:keyPath] addObject: [[obj objectAtIndex:0] lastPathComponent]];
					break;

				default:
					break;
			}
		}
	}
}
@end
