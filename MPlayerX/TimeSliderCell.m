/*
 * MPlayerX - TimeSliderCell.m
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

#import "TimeSliderCell.h"

@interface TimeSliderCell (SliderCellInternal)
-(NSColor *)sliderTrackColor;
-(NSColor *)strokeColor;
-(NSColor *)disabledSliderTrackColor;
-(NSColor *)disabledStrokeColor;
-(NSShadow *)focusRing;
-(NSShadow *)dropShadow;
-(NSGradient *)highlightKnobColor;
-(NSGradient *)knobColor;
-(NSGradient *)disabledKnobColor;
@end


@implementation TimeSliderCell

- (void)drawHorizontalBarInFrame:(NSRect)frame {
	
	// Adjust frame based on ControlSize
	switch ([self controlSize]) {
			
		case NSRegularControlSize:
			
			if([self numberOfTickMarks] != 0) {
				
				if([self tickMarkPosition] == NSTickMarkBelow) {
					
					frame.origin.y += 4;
				} else {
					
					frame.origin.y += frame.size.height - 10;
				}
			} else {
				
				frame.origin.y = frame.origin.y + (((frame.origin.y + frame.size.height) /2) - 2.5f);
			}
			
			frame.origin.x += 2.5f;
			frame.origin.y += 0.5f;
			frame.size.width -= 5;
			frame.size.height = 5;
			break;
			
		case NSSmallControlSize:
			
			if([self numberOfTickMarks] != 0) {
				
				if([self tickMarkPosition] == NSTickMarkBelow) {
					
					frame.origin.y += 2;
				} else {
					
					frame.origin.y += frame.size.height - 8;
				}
			} else {
				
				frame.origin.y = frame.origin.y + (((frame.origin.y + frame.size.height) /2) - 2.5f);
			}
			
			frame.origin.x += 0.5f;
			frame.origin.y += 0.5f;
			frame.size.width -= 1;
			frame.size.height = 5;
			break;
			
		case NSMiniControlSize:
			
			if([self numberOfTickMarks] != 0) {
				
				if([self tickMarkPosition] == NSTickMarkBelow) {
					
					frame.origin.y += 2;
				} else {
					
					frame.origin.y += frame.size.height - 6;
				}
			} else {
				
				frame.origin.y = frame.origin.y + (((frame.origin.y + frame.size.height) /2) - 2);
			}
			
			frame.origin.x += 0.5f;
			frame.origin.y += 0.5f;
			frame.size.width -= 1;
			frame.size.height = 3;
			break;
	}
	
	//Draw Bar
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: frame xRadius: 2 yRadius: 2];
	
	if([self isEnabled]) {
		
		[[self sliderTrackColor] set];
		[path fill];
		
		[[self strokeColor] set];
		[path stroke];
	} else {
		
		[[self disabledSliderTrackColor] set];
		[path fill];
		
		[[self disabledStrokeColor] set];
		[path stroke];
	}
}

- (void)drawHorizontalKnobInFrame:(NSRect)frame {
	
	NSRect rcBounds = [[self controlView] bounds];
	NSBezierPath *path;
	
	switch ([self controlSize]) {
			
		case NSRegularControlSize:
			
			if([self numberOfTickMarks] != 0) {
				
				if([self tickMarkPosition] == NSTickMarkAbove) {
					
					frame.origin.y += 2;
				}
				
				frame.origin.x += 2;
				frame.size.height = 19.0f;
				frame.size.width = 15.0f;
			} else {
				
				frame.origin.x += 3;
				frame.origin.y += 3;
				frame.size.height = 15;
				frame.size.width = 15;
			}
			break;
			
		case NSSmallControlSize:
			rcBounds.origin.y = rcBounds.origin.y + (((rcBounds.origin.y + rcBounds.size.height) /2) - 2.5f);
			rcBounds.origin.x += 0.5f;
			rcBounds.origin.y += 0.5f;
			rcBounds.size.width -= 1;
			rcBounds.size.height = 5;
			
			rcBounds.size.width *= ([self floatValue]/[self maxValue]);
			
			path = [NSBezierPath bezierPathWithRoundedRect:rcBounds xRadius:2 yRadius:2];
			
			if([self isEnabled]) {
				[[self strokeColor] set];
			} else {
				[[self disabledStrokeColor] set];
			}
			[path fill];
			break;
			
		case NSMiniControlSize:
			
			if([self numberOfTickMarks] != 0) {
				
				frame.origin.x += 1;
				frame.size.height = 11.0f;
				frame.size.width = 9.0f;
			} else {
				
				frame.origin.x += 2;
				frame.origin.y += 1;
				frame.size.height = 9;
				frame.size.width = 9;
			}
			break;
	}
}

- (BOOL)_usesCustomTrackImage {
	
	return YES;
}

#pragma mark -

#pragma mark internal
-(NSColor *)sliderTrackColor {
	return [NSColor colorWithDeviceRed: 0 green: 0 blue: 0 alpha: 0.5];
}

-(NSColor *)strokeColor {
	
	return [NSColor colorWithDeviceRed: 0.749f green: 0.761f blue: 0.788f alpha: 1.0];
}

-(NSColor *)disabledSliderTrackColor {
	
	return [NSColor colorWithDeviceRed: 0 green: 0 blue: 0 alpha: 0.2];
}

-(NSColor *)disabledStrokeColor {
	
	return [NSColor colorWithDeviceRed: 0.749f green: 0.761f blue: 0.788f alpha: 0.2];
}

-(NSShadow *)focusRing {
	
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowColor: [NSColor whiteColor]];
	[shadow setShadowBlurRadius: 3];
	[shadow setShadowOffset: NSMakeSize( 0, 0)];
	
	return [shadow autorelease];
}

-(NSShadow *)dropShadow {
	
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowColor: [NSColor blackColor]];
	[shadow setShadowBlurRadius: 2];
	[shadow setShadowOffset: NSMakeSize( 0, -1)];
	
	return [shadow autorelease];
}

-(NSGradient *)highlightKnobColor {
	
	return [[[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.451f green: 0.451f blue: 0.455f alpha: 1.0f]
										  endingColor: [NSColor colorWithDeviceRed: 0.318f green: 0.318f blue: 0.318f alpha: 1.0f]] autorelease];
}

-(NSGradient *)knobColor {
	
	return [[[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.251f green: 0.251f blue: 0.255f alpha: 1.0f]
										  endingColor: [NSColor colorWithDeviceRed: 0.118f green: 0.118f blue: 0.118f alpha: 1.0f]] autorelease];
}

-(NSGradient *)disabledKnobColor {
	
	return [[[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.251f green: 0.251f blue: 0.255f alpha: 1.0f]
										  endingColor: [NSColor colorWithDeviceRed: 0.118f green: 0.118f blue: 0.118f alpha: 1.0f]] autorelease];
}

@end
