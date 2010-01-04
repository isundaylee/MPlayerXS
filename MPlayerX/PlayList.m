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

NSUInteger findLastDigitPartIndex(NSString *name)
{
	NSUInteger idx = [name length] - 1;
	unichar ch;
	
	while (idx >= 0) {
		ch = [name characterAtIndex:idx];
		if ((ch < '0')||(ch>'9'))
			break;
		idx--;
	}
	return (idx+1);
}

@implementation PlayList

+(NSString*) AutoSearchNextMoviePathFrom:(NSString*) path
{
	NSString *nextPath = nil;
	NSUInteger digitPathIdx;
	NSString *idxNext;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (path) {
		// 得到文件的名字，没有后缀
		NSString *movieName = [[path lastPathComponent] stringByDeletingPathExtension];
		// 文件名的长度
		NSUInteger movieNameLength = [movieName length];
		// 找到数字开头的index
		digitPathIdx = findLastDigitPartIndex(movieName);
		
		// 如果文件后面有数字的话
		if (digitPathIdx < movieNameLength) {
			// 得到下一个想要播放的文件的index
			idxNext = [NSString stringWithFormat:@"%d", [[movieName substringFromIndex:digitPathIdx] integerValue] + 1];
			NSUInteger idxNextLen = [idxNext length];
			
			// 如果这个index的长度比上一个短，说明有padding
			if (idxNextLen < (movieNameLength - digitPathIdx)) {
				NSRange range;
				range.location = digitPathIdx;
				range.length = ((movieNameLength - digitPathIdx) - idxNextLen);
				
				// padding之后的文件名
				idxNext = [NSString stringWithFormat: @"%@%@", [movieName substringWithRange:range], idxNext];
			}

			nextPath = [[NSString alloc] initWithFormat:@"%@/%@%@.%@",
						[path stringByDeletingLastPathComponent],
						[movieName substringToIndex:digitPathIdx],
						idxNext,
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