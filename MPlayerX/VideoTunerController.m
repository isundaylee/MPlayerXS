/*
 * MPlayerX - VideoTunerController.m
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

#import "VideoTunerController.h"
#import <Quartz/Quartz.h>

@implementation VideoTunerController

-(id) init
{
	if (self = [super init]) {
		nibLoaded = NO;
		
		// 设置name是为了能够通过keyPath访问filter
		// 但是残念，因为layer的filters是NSArray，无法实现通过name的binding
		CIFilter *colorFilter = [CIFilter filterWithName:@"CIColorControls"];
		[colorFilter setName:@"colorFilter"];
		[colorFilter setDefaults];
		
		CIFilter *nrFilter = [CIFilter filterWithName:@"CINoiseReduction"];
		[nrFilter setName:@"nrFilter"];
		[nrFilter setDefaults];
		
		filters = [[NSArray alloc] initWithObjects:colorFilter, nrFilter, nil];
		
		layer = nil;
	}
	return self;
}

-(void) dealloc
{
	[filters release];
	
	[super dealloc];
}

-(IBAction)showUI:(id)sender
{
	if (!nibLoaded) {
		[NSBundle loadNibNamed:@"VideoTuner" owner:self];
		nibLoaded = YES;
	}

	[VTWin makeKeyAndOrderFront:self];
}

-(void) setLayer:(CALayer*)l
{
	if (layer) {
		[layer setFilters:nil];
	}
	layer = l;
	if (layer) {
		[layer setFilters:filters];
	}
}
@end
