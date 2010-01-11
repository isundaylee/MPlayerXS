/*
 * MPlayerX - TimeFormatter.m
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

#import "TimeFormatter.h"


@implementation TimeFormatter


- (NSString *)stringForObjectValue:(id)obj
{
	NSInteger time = [obj integerValue];
	NSInteger hour, minute, sec;
	NSString *formatString;
	
	if (time < 0) {
		time = -time;
		formatString = @"-";
	} else {
		formatString = @"";
	}

	sec = time % 60;
	time = (time -sec) / 60;
	
	minute = time % 60;
	hour = (time - minute) / 60;
	
	if (hour != 0) {
		return [formatString stringByAppendingFormat:@"%d:%02d:%02d", hour, minute, sec];		
	} else if (minute != 0) {
		return [formatString stringByAppendingFormat:@"%d:%02d", minute, sec];
	} else {
		return [formatString stringByAppendingFormat:@"%d\"", sec];
	}
}

- (BOOL)getObjectValue:(out id *)obj forString:(NSString *)string errorDescription:(out NSString **)error
{
	if (![string isEqualToString:@""]) {
		*obj = [NSNumber numberWithFloat:[string floatValue]];
		return YES;		
	}
	return NO;
}

@end
