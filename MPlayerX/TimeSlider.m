/*
 * MPlayerX - TimeSlider.m
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

#import "TimeSlider.h"


@implementation TimeSlider

@synthesize timeDest;

-(void) awakeFromNib
{
	timeDest = 0;
}

-(void) mouseDown:(NSEvent *)theEvent
{
	if ([self isEnabled]) {
		NSPoint pos = [theEvent locationInWindow];
		pos = [self convertPoint:pos fromView:nil];
		
		timeDest = (pos.x * [self maxValue])/ self.bounds.size.width;
		
		[self.target performSelector:self.action withObject:self];		
	}
}
-(void) mouseDragged:(NSEvent *)theEvent
{
	
}
@end
