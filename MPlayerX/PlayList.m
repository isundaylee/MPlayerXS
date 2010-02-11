/*
 * MPlayerX - PlayList.m
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

#import "PlayList.h"

NSRange findLastDigitPart(NSString *name)
{
	unichar ch;
	NSRange range;
	BOOL entered = NO;
	
	range.location = [name length];
	range.length = 0;
	
	// 字符串长度大于0
	while(range.location--) {
		// 得到当前的char
		ch = [name characterAtIndex:range.location];
		
		if ((ch>='0')&&(ch<='9')) {
			// 是数字
			entered = YES;
			range.length++;
		} else if (entered) {
			// 不是数字并且已经找到了数字
			break;
		}
	}
	range.location++;
 	return range;
}

@implementation PlayList

+(NSString*) AutoSearchNextMoviePathFrom:(NSString*) path
{
	NSString *nextPath = nil;
	NSRange digitRange;
	NSString *idxNext;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (path) {
		// 得到文件的名字，没有后缀
		NSString *movieName = [[path lastPathComponent] stringByDeletingPathExtension];
		// 找到数字开头的index
		digitRange = findLastDigitPart(movieName);
		
		// 如果文件后面有数字的话
		if (digitRange.length) {
			// 得到下一个想要播放的文件的index
			idxNext = [NSString stringWithFormat:@"%d", [[movieName substringWithRange:digitRange] integerValue] + 1];
			NSUInteger idxNextLen = [idxNext length];
			
			// 如果这个index的长度比上一个短，说明有padding
			if (idxNextLen < digitRange.length) {
				digitRange.location += (digitRange.length-idxNextLen);
				digitRange.length = idxNextLen;
			}
			
			nextPath = [[NSString alloc] initWithFormat:@"%@/%@%@%@.%@",
						[path stringByDeletingLastPathComponent],
						[movieName substringToIndex:digitRange.location],
						idxNext,
						[movieName substringFromIndex:digitRange.location+digitRange.length],
						[path pathExtension]];
			
			BOOL isDir = YES;
			if ((![[NSFileManager defaultManager] fileExistsAtPath:nextPath  isDirectory:&isDir]) || isDir) {
				[nextPath release];
				nextPath = nil;
			}
		}
	}
	[pool release];
	
	return [nextPath autorelease];
}
@end