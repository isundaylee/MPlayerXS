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

#define kOSDAutoHideTimeInterval	(5)
#define kOSDFontSizeMin				(24)
#define kOSDFontSizeMax				(60)
#define kOSDFontSizeRatio			(50)

@implementation OsdText

@synthesize active;

-(id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder]) {
		active = NO;
		autoHideTimeInterval = 0;
		autoHideTimer = nil;
		shouldHide = YES;
		
		frontColor = [[NSColor whiteColor] retain];
		
		shadow = [[NSShadow alloc] init];
		[shadow setShadowOffset:NSMakeSize(0, 0)];
		[shadow setShadowColor:[NSColor blackColor]];
		[shadow setShadowBlurRadius:8];		
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
	
	dispView = [self superview];
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
		autoHideTimeInterval = ti;
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

-(void) setStringValue:(NSString *)aString updateTimer:(BOOL) ut
{
	if (active) {
		if (!aString) {
			// 如果是nil，那么就用本来就有的
			aString = [self stringValue];
		}

		NSSize sz = [dispView bounds].size;
		
		NSFont *font = [NSFont systemFontOfSize:MIN(kOSDFontSizeMax, MAX(kOSDFontSizeMin, (sz.width + sz.height) / kOSDFontSizeRatio))];
		
		NSDictionary *attrDict = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName,
								  frontColor, NSForegroundColorAttributeName,
								  shadow, NSShadowAttributeName, nil];
		NSAttributedString *str = [[NSAttributedString alloc] initWithString:aString attributes:attrDict];
		[self setObjectValue:str];
		
		[self setAlphaValue:1];
		
		[attrDict release];
		[str release];

		if (ut) {
			shouldHide = NO;
		}
	}
}
@end
