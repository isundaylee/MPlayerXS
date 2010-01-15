/*
 * MPlayerX - OsdText.m
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

#import "OsdText.h"

#define kOSDAutoHideTimeInterval	(2)
#define kOSDFontSizeMin				(12)
#define kOSDFontSizeMax				(48)
#define kOSDFontSizeRatio			(50)

@implementation OsdText

-(id) init
{
	if (self = [super init]) {
		active = NO;
		autoHideTimeInterval = 0;
		autoHideTimer = nil;
		shouldHide = YES;
		
		frontColor = [[NSColor whiteColor] retain];

		shadow = [[NSShadow alloc] init];
		[shadow setShadowOffset:NSMakeSize(0, 0)];
		[shadow setShadowColor:[NSColor blackColor]];
		[shadow setShadowBlurRadius:4];
	}
	return self;
}

-(void) awakeFromNib
{
	[self setAlphaValue:0];

	[self setSelectable:NO];
	[self setAllowsEditingTextAttributes:YES];
	[self setDrawsBackground:NO];
	[self setBezeled:NO];

	[self setAutoHideTimeInterval:kOSDAutoHideTimeInterval];
	
	dispView = [self superView];
}

-(void) dealloc
{
	[frontColor release];
	[shadow release];
	
	if (autoHideTimer) {
		[autoHideTimer invalidate];
	}
	[super dealloc];
}

-(void) setActive:(BOOL) act
{
	active = act;
	if (!active) {
		[self setAlphaValue:0];
	}
}

-(void) setAutoHideTimeInterval:(NSTimeInterval)ti
{
	if (autoHideTimer) {
		[autoHideTimer invalidate];
		autoHideTimer = nil;
	}
	if (ti > 0) {
		autoHideTimer = [NSTimer scheduledTimerWithTimeInterval:autoHideTimeInterval/2
														 target:self
													   selector:@selector(tryToHide)
													   userInfo:nil
														repeats:YES];
		NSRunLoop *rl = [NSRunLoop currentRunLoop];
		[rl addTimer:autoHideTimer forMode:NSDefaultRunLoopMode];
		[rl addTimer:autoHideTimer forMode:NSModalPanelRunLoopMode];
		[rl addTimer:autoHideTimer forMode:NSEventTrackingRunLoopMode];
	}
}

-(void) tryToHide
{
	if (shouldHide) {
		[self.animator setAlphaValue:0];
	} else {
		shouldHide = YES;
	}
}

-(void) setStringValue:(NSString *)aString
{
	if (active && aString) {
	
		NSSize sz = [dispView bounds].size;

		NSFont *font = [NSFont systemFontOfSize:MIN(kOSDFontSizeMax, MAX(kOSDFontSizeMin, (sz.width + sz.height) / kOSDFontSizeRatio))];
		
		NSDictionary *attrDict = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName,
																			  frontColor, NSForegroundColorAttributeName,
																			  shadow, NSShadowAttributeName, nil];
		NSAttributedString *str = [[NSAttributedString alloc] initWithString:aString attributes:attrDict];
		[self setAttributedString:str];
		
		[self setAlphaValue:1];
		
		[attrDict release];
		[str release];
		
		shouldHide = NO;
	}
}
@end
