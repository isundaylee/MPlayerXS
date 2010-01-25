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
#import <UniversalDetector/UniversalDetector.h>

@implementation SubConverter

-(id) init
{
	if (self = [super init]) {
		textSubFileExts = [[NSSet alloc] initWithObjects:@"utf", @"utf8", @"srt", @"ass", @"smi", @"txt", @"ssa", nil];
		workDirectory = nil;
		detector = [[UniversalDetector alloc] init];
		[detector reset];
	}
	return self;
}

-(void) dealloc
{
	[textSubFileExts release];
	[workDirectory release];
	[detector release];
	
	[super dealloc];
}

-(void) clearWorkDirectory
{
	if (workDirectory) {
		[[NSFileManager defaultManager] removeItemAtPath:[workDirectory stringByAppendingPathComponent:@"Subs"] error:NULL];
	}
}

-(void) setWorkDirectory:(NSString *)wd
{
	[self clearWorkDirectory];

	[wd retain];
	[workDirectory release];
	workDirectory = wd;
}

-(BOOL) isTextSubFile:(NSString*) subPath
{
	return [textSubFileExts containsObject:[[subPath pathExtension] lowercaseString]];
}

-(NSString*) getCPOfTextSubtitle:(NSString*)path
{
	BOOL isDir = YES;
	NSString *cpStr = nil;	
	
	if (path && [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && (!isDir)) {

		[detector analyzeContentsOfFile:path];
		cpStr = [[detector MIMECharset] retain];
		[detector reset];
	}
	return [cpStr autorelease];
}

-(NSArray*) convertTextSubsAndEncodings:(NSDictionary*)subEncDict
{
	if (!workDirectory) {
		return nil;
	}
	
	NSString *subDir = [workDirectory stringByAppendingPathComponent:@"Subs"];
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	
	if ([fm fileExistsAtPath:subDir isDirectory:&isDir] && (!isDir)) {
		// 如果存在但不是文件夹的话
		[fm removeItemAtPath:subDir error:NULL];
	}
	
	if (!isDir) {
		// 如果原来不存在这个文件夹或者存在的是文件的话，都需要重建文件夹
		if (![fm createDirectoryAtPath:subDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
			return nil;
		}
	}

	NSMutableArray *newSubs = [[NSMutableArray alloc] initWithCapacity:4];
	NSString *subPathOld, *enc, *subFileOld, *subPathNew, *ext, *prefix;
	NSUInteger idx;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	for (subPathOld in subEncDict) {
		// 得到文件的编码
		enc = [subEncDict objectForKey:subPathOld];
		
		if (enc) {
			// 如果能够得到编码字符串，先转换为CF格式
			CFStringEncoding ce = CFStringConvertIANACharSetNameToEncoding((CFStringRef)enc);

			subPathNew = [subDir stringByAppendingPathComponent:[subPathOld lastPathComponent]];
			
			// 因为有可能会有重名的情况，所以这里要找到合适的文件名
			isDir = YES;
			idx = 0;
			ext = [subPathNew pathExtension];
			prefix = [subPathNew stringByDeletingPathExtension];
			
			while([fm fileExistsAtPath:subPathNew isDirectory:&isDir] && (!isDir)) {
				// 如果该文件存在那么就寻找下一个不存在的文件名
				subPathNew = [prefix stringByAppendingFormat:@".mpx.%d.%@", idx++, ext];
			}
			
			if (ce != kCFStringEncodingInvalidId) {
				// CP949据说总会fallback到EUC_KR，这里把它回到CP949(kCFStringEncodingDOSKorean)
				if ((ce == kCFStringEncodingMacKorean) || (ce == kCFStringEncodingEUC_KR)) {
					ce = kCFStringEncodingDOSKorean;
				}
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

-(NSDictionary*) getCPFromMoviePath:(NSString*)moviePath nameRule:(SUBFILE_NAMERULE)nameRule alsoFindVobSub:(NSString**)vobPath
{
	NSString *cpStr = nil;
	NSString *subPath = nil;
	NSMutableDictionary *subEncDict = [[NSMutableDictionary alloc] initWithCapacity:2];

	if (vobPath) {
		*vobPath = nil;
	}

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// 文件夹路径
	NSString *directoryPath = [moviePath stringByDeletingLastPathComponent];
	// 播放文件名称
	NSString *movieName = [[moviePath lastPathComponent] stringByDeletingPathExtension];
	
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
	
	// 遍历播放文件所在的目录
	for (NSString *path in directoryEnumerator)
	{
		NSDictionary *fileAttr = [directoryEnumerator fileAttributes];
		
		if ([fileAttr objectForKey:NSFileType] == NSFileTypeDirectory) { //不遍历子目录
			[directoryEnumerator skipDescendants];
			
		} else if ([[fileAttr objectForKey:NSFileType] isEqualToString: NSFileTypeRegular]) {
			// 如果是普通文件
			switch (nameRule) {
				case kSubFileNameRuleExactMatch:
					if (![movieName isEqualToString:[path stringByDeletingPathExtension]]) continue; // exact match
					break;
				case kSubFileNameRuleAny:
					break; // any sub file is OK
				case kSubFileNameRuleContain:
					if ([path rangeOfString: movieName].location == NSNotFound) continue; // contain the movieName
					break;
				default:
					continue;
					break;
			}
			
			subPath = [directoryPath stringByAppendingPathComponent:path];

			NSString *ext = [[path pathExtension] lowercaseString];
			
			if ([textSubFileExts containsObject: ext]) {
				// 如果是文本字幕文件
				[detector analyzeContentsOfFile: subPath];
				
				cpStr = [detector MIMECharset];
				
				if (cpStr) {
					// 如果猜出来了，不管有多少的确认率
					[subEncDict setObject:[cpStr uppercaseString] forKey:subPath];
				} else {
					// 如果没有猜出来，那么设为空
					[subEncDict setObject:@"" forKey:subPath];
				}
				[detector reset];				
			} else if (vobPath && [ext isEqualToString:@"sub"]) {
				// 如果是vobsub并且设定要寻找vobsub
				[*vobPath release];
				*vobPath = [subPath retain];
			}
		}
	}
	[pool release];

	if (vobPath && (*vobPath)) {
		[*vobPath autorelease];
	}

	return [subEncDict autorelease];	
}

@end
