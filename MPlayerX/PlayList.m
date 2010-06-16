/*
 * MPlayerX - PlayList.m
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

#import "PlayList.h"
#import "def.h"

NSArray* findLastDigitPart(NSString *name)
{
	unichar ch;
	NSRange range;
	NSMutableArray *ret = [[NSMutableArray alloc] initWithCapacity:5];;
	
	range.location = [name length];
	range.length = 0;
	
	// 字符串长度大于0
	while(range.location--) {
		// 得到当前的char
		ch = [name characterAtIndex:range.location];
		
		if ((ch>='0')&&(ch<='9')) {
			// 是数字
			range.length++;
		} else if (range.length > 0) {
			// 不是数字并且已经找到了数字
			[ret addObject:[NSValue valueWithRange:NSMakeRange(range.location+1, range.length)]];
			range.length = 0;
		}
	}
	if (range.length > 0) {
		[ret addObject:[NSValue valueWithRange:NSMakeRange(0, range.length)]];
	}
	return [ret autorelease];
}

@implementation PlayList

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithBool:NO], kUDKeyAPNFuzzy,
					   nil]];
}

+(NSString*) AutoSearchNextMoviePathFrom:(NSString*)path inFormats:(NSSet*)exts
{
	NSString *nextPath = nil;
	NSMutableArray *filesCandidates = nil;
	
	if (path) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSRange digitRange;
		NSString *idxNext;
		BOOL isDir;
		// 得到文件的名字，没有后缀
		NSString *movieName = [[path lastPathComponent] stringByDeletingPathExtension];
		// directory path
		NSString *dirPath = [path stringByDeletingLastPathComponent];
		
		// 找到数字开头的index
		NSArray *digitRangeArray = findLastDigitPart(movieName);
		
		for (NSValue *val in digitRangeArray) {
			digitRange = [val rangeValue];
			
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
				
				NSString *fileNamePrefix = [[movieName substringToIndex:digitRange.location] stringByAppendingString:idxNext];
				
				if ([[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyAPNFuzzy]) {
					// fuzzy matching
					if (!filesCandidates) {
						// lazy load
						filesCandidates = [[NSMutableArray alloc] initWithCapacity:20];
						
						NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:dirPath];
						
						for (NSString *file in directoryEnumerator) {
							// enum the folder
							NSDictionary *fileAttr = [directoryEnumerator fileAttributes];
							
							if ([[fileAttr objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
								// skip all sub-folders
								[directoryEnumerator skipDescendants];
								
							} else if ([[fileAttr objectForKey:NSFileType] isEqualToString: NSFileTypeRegular] &&
									   [exts containsObject:[[file pathExtension] lowercaseString]]) {
								// the normal file and the file extension is OK
								[filesCandidates addObject:file];
							}
						}
					}
					
					NSRange rng;
					for (NSString *name in filesCandidates) {
						rng = [name rangeOfString:fileNamePrefix options:NSCaseInsensitiveSearch|NSAnchoredSearch];
						if (rng.length != 0) {
							// found the name
							nextPath = [[dirPath stringByAppendingPathComponent:name] retain];
							goto ExitLoop;
						}
					}
				} else {
					// exactly matching
					nextPath = [[NSString alloc] initWithFormat:@"%@/%@%@.%@",
								dirPath,
								fileNamePrefix,
								[movieName substringFromIndex:digitRange.location+digitRange.length],
								[path pathExtension]];
					
					// NSLog(@"Next File:%@", nextPath);
					
					isDir = YES;
					if ((![[NSFileManager defaultManager] fileExistsAtPath:nextPath  isDirectory:&isDir]) || isDir) {
						[nextPath release];
						nextPath = nil;
					} else {
						goto ExitLoop;
					}
				}
			}
		}
ExitLoop:
		[pool drain];
	}
	
	[filesCandidates release];
	
	return [nextPath autorelease];
}
@end