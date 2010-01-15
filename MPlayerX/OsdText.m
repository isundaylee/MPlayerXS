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

#import "def.h"
#import "OsdText.h"

#define kOSDAutoHideTimeInterval	(5)

#define kOSDFontSizeMinDefault		(24)
#define kOSDFontSizeMaxDefault		(50)
#define kOSDFontSizeLimitMin		(12)
#define kOSDFontSizeLimitMax		(100)

#define kOSDFontSizeRatio			(40)

@implementation OsdText

@synthesize active;
@synthesize owner;

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithFloat:kOSDFontSizeMaxDefault], kUDKeyOSDFontSizeMax,
	  [NSNumber numberWithFloat:kOSDFontSizeMinDefault], kUDKeyOSDFontSizeMin,
	  nil]];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder]) {
		ud = [NSUserDefaults standardUserDefaults];
		
		fontSizeMin = [ud floatForKey:kUDKeyOSDFontSizeMin];
		fontSizeMax = [ud floatForKey:kUDKeyOSDFontSizeMax];
		
		active = NO;
		autoHideTimeInterval = 0;
		autoHideTimer = nil;
		shouldHide = YES;
		owner = nil;
		
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
	[owner release];
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

-(void) setStringValue:(NSString *)aString owner:(NSString*)ow updateTimer:(BOOL)ut
{
	if (active) {
		if (ut || ([self alphaValue] > 0 && [owner isEqualToString:ow])) {
			if (!aString) {
				// 如果是nil，那么就用本来就有的
				aString = [self stringValue];
			}
			
			NSSize sz = [dispView bounds].size;
			
			float fontSize = MIN(fontSizeMax, MAX(fontSizeMin, (sz.width + sz.height) / kOSDFontSizeRatio));
			fontSize = MIN(kOSDFontSizeLimitMax, MAX(kOSDFontSizeLimitMin, fontSize));
						   
			NSFont *font = [NSFont systemFontOfSize:fontSize];
			
			NSDictionary *attrDict = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName,
									  frontColor, NSForegroundColorAttributeName,
									  shadow, NSShadowAttributeName, nil];
			NSAttributedString *str = [[NSAttributedString alloc] initWithString:aString attributes:attrDict];
			[self setObjectValue:str];
			
			[self setAlphaValue:1];
			
			[str release];
			[attrDict release];			
		}
		if (ut) {
			[owner release];
			owner = [ow retain];
			
			shouldHide = NO;
		}
	}
}
@end
