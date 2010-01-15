/*
 * MPlayerX - OsdText.h
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

#import <Cocoa/Cocoa.h>

@interface OsdText : NSTextField
{
	BOOL active;
	BOOL shouldHide;
	NSColor *frontColor;
	NSShadow *shadow;

	NSTimer *autoHideTimer;
	NSTimeInterval autoHideTimeInterval;
	
	NSView *dispView;
}

@property (assign, readwrite, getter=isActive) BOOL active;

-(void) setAutoHideTimeInterval:(NSTimeInterval)ti;

@end
