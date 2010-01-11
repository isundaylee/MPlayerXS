/*
 * MPlayerX - SubConverter.m
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

#import "SubConverter.h"


@implementation SubConverter

-(id) init
{
	if (self = [super init]) {
		workDirectory = nil;
	}
	return self;
}

-(void) dealloc
{
	[workDirectory release];
	
	[super dealloc];
}

-(void) clearWorkDirectory
{
	if (workDirectory) {
		[[NSFileManager defaultManager] removeItemAtPath:[workDirectory stringByAppendingString:@"/Subs"] error:NULL];
	}
}

-(void) setWorkDirectory:(NSString *)wd
{
	[self clearWorkDirectory];

	[wd retain];
	[workDirectory release];
	workDirectory = wd;
}

-(NSArray*) convertTextSubsAndEncodings:(NSDictionary*)subEncDict
{
	if (!workDirectory) {
		return nil;
	}
	
	NSString *subDir = [workDirectory stringByAppendingString:@"/Subs"];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// 删除文件夹
	[fm removeItemAtPath:subDir error:NULL];
	
	// 创建sub工作文件夹
	if (![fm createDirectoryAtPath:subDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
		return nil;
	}
	
	NSMutableArray *newSubs = [[NSMutableArray alloc] initWithCapacity:2];
	NSString *subPathOld, *enc, *subFileOld, *subPathNew;
	BOOL isDir;

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	for (subPathOld in subEncDict) {
		// 得到文件的编码
		enc = [subEncDict objectForKey:subPathOld];
		
		if (enc) {
			// 如果能够得到编码字符串，先转换为CF格式
			CFStringEncoding ce = CFStringConvertIANACharSetNameToEncoding((CFStringRef)enc);
			
			subPathNew = [subDir stringByAppendingPathComponent:[subPathOld lastPathComponent]];

			if (ce != kCFStringEncodingInvalidId) {
				// 如果合法就转码
				NSStringEncoding ne = CFStringConvertEncodingToNSStringEncoding(ce);
				
				subFileOld = [NSString stringWithContentsOfFile:subPathOld encoding:ne error:NULL];
				
				if (subFileOld) {
					// 成功读出文件
					// 因为UCD也有猜错的时候，这个时候就直接拷贝文件了
					if ([subFileOld writeToFile:subPathNew atomically:NO encoding:NSUTF8StringEncoding error:NULL]) {
						// 如果成功写入
						// 如果没有些成功，那就试着直接拷贝
						[newSubs addObject:subPathNew];
						continue;
					}
				}
			}
			isDir = YES;
			if ([fm fileExistsAtPath:subPathOld isDirectory:&isDir] && (!isDir)) {
				// 文件确实存在
				if ([fm copyItemAtPath:subPathOld toPath:subPathNew error:NULL]) {
					// 拷贝成功的话
					[newSubs addObject:subPathNew];
				}
			}
		}
	}
	[pool release];
	
	return [newSubs autorelease];
}
@end
