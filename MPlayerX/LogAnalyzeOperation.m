/*
 * MPlayerX - LogAnalyzeOperation.m
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

#import "LogAnalyzeOperation.h"

@implementation LogAnalyzeOperation

-(id) initWithData:(NSData*)analyzeData whenFinishedTarget:(id) target selector:(SEL) selector;
{
	if (self = [super init]) {
		if (analyzeData) {
			log = [analyzeData retain];
			result = [[NSMutableDictionary alloc] initWithCapacity:1];
			
		} else {
			log = nil;
		}
		tgt = target;
		sel = selector;
	}
	return self;
}

-(void) dealloc
{
	[log release];
	[result release];
	[super dealloc];
}

const char* findValidStart(const char*head, const char *end)
{
	if (((end - head) > 4) && (head[0] == 'A')&&(head[1] == 'N')&&(head[2] == 'S')&&(head[3] == '_')) {
		return (head+4);

	} else if (((end - head) > 3) && (head[0] == 'I')&&(head[1] == 'D')&&(head[2] == '_'))	{
		return (head+3);
		
	} else if (((end - head) > 4) && (head[0] == 'M')&&(head[1] == 'P')&&(head[2] == 'X')&&(head[3] == '_')) {
		return (head+4);
	}
	return NULL;
}

const char* findNextReturnMark(const char *head, const char *end, const char **split)
{
	*split = NULL;
	while (head < end) {
		if (*head == '\n') {
			return head;
			
		} else if(*head == '=') {
			// 如果一行出现多个分隔符，那么将返回最远的一个分隔符
			*split = head;
		}
		head++;
	}
	return NULL;
}

- (void) main
{
	if (log) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		const char *dataHead = [log bytes];
		const char *dataEnd  = dataHead + [log length];
		const char *retMark = NULL;
		const char *splitMark = NULL;
		const char *validStart = NULL;
		NSString *var;
		NSString *val;
		
		while (dataHead < dataEnd) {
			retMark = findNextReturnMark(dataHead, dataEnd, &splitMark);
			
			if (retMark == NULL) { retMark = dataEnd -1; }
			
			if (splitMark) {
				// 如果有分隔符的话
				validStart = findValidStart(dataHead, splitMark);
				if (validStart) {
					// 后半段是 value
					val = [[NSString alloc] initWithBytes:(splitMark+1) length:(retMark-splitMark-1) encoding:NSUTF8StringEncoding];
					// 前半段是 key
					var = [[NSString alloc] initWithBytes:validStart length:(splitMark-validStart) encoding:NSUTF8StringEncoding];
					
					if (val && var) {
						[result setObject:val forKey:var];
					}
					[val release];
					[var release];
				}
			} else {
				
			}
			dataHead = retMark +1;		
		}
		if (([self isCancelled] == NO) && tgt && ([result count])) {
			// NSLog(@"%@",result);
			[tgt performSelector:sel withObject:result];
		}
		[pool release];
	}
}
@end
