/*
 * MPlayerX - VideoInfo.m
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

#import "VideoInfo.h"


@implementation VideoInfo

@synthesize codec;
@synthesize format;
@synthesize bitRate;
@synthesize width;
@synthesize height;
@synthesize fps;
@synthesize aspect;

-(id) init
{
	if (self = [super init]) {
		codec = nil;
		format = -1;
		bitRate = 0;
		width = 0;
		height = 0;
		fps = 0;
		aspect = 0;
	}
	return self;
}

-(void) dealloc
{
	[codec release];
	[super dealloc];
}
@end
