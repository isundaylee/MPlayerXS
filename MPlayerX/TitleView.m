/*
 * MPlayerX - TitleView.m
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

#import "TitleView.h"
#import "def.h"

@implementation TitleView

@synthesize title;

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame]) {
		NSUInteger styleMask = NSTitledWindowMask|NSResizableWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
		
		closeButton = [[NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:styleMask] retain];
		miniButton  = [[NSWindow standardWindowButton:NSWindowMiniaturizeButton forStyleMask:styleMask] retain];
		zoomButton  = [[NSWindow standardWindowButton:NSWindowZoomButton forStyleMask:styleMask] retain];
		
		title = nil;
		titleAttr = [[NSDictionary alloc]
					 initWithObjectsAndKeys:
					 [NSColor whiteColor], NSForegroundColorAttributeName,
					 [NSFont titleBarFontOfSize:12], NSFontAttributeName,
					 nil];
		frame.size.width = 64;
		frame.size.height = 20;
		frame.origin.x = 1;
		frame.origin.y = 1;
		trackArea = nil;
		// [self addTrackingArea:trackArea];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationWillBecomeActive:)
													 name:NSApplicationWillBecomeActiveNotification
												   object:NSApp];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationWillResignActive:)
													 name:NSApplicationWillResignActiveNotification
												   object:NSApp];
    }
    return self;
}

-(void) dealloc
{
	// [self removeTrackingArea:trackArea];
	[trackArea release];
	
	[title release];
	[titleAttr release];
	
	[closeButton release];
	[miniButton release];
	[zoomButton release];
	
	[tbCornerLeft release];
	[tbCornerRight release];
	[tbMiddle release];
	
	[super dealloc];
}

-(void) awakeFromNib
{
	[self addSubview:closeButton];
	[closeButton setFrameOrigin:NSMakePoint(9.0, 2.0)];
	[closeButton setAutoresizingMask:NSViewMaxXMargin|NSViewMaxYMargin];
	
	[self addSubview:miniButton];
	[miniButton setFrameOrigin:NSMakePoint(30.0, 2.0)];
	[miniButton setAutoresizingMask:NSViewMaxXMargin|NSViewMaxYMargin];
	
	[self addSubview:zoomButton];
	[zoomButton setFrameOrigin:NSMakePoint(51.0, 2.0)];
	[zoomButton setAutoresizingMask:NSViewMaxXMargin|NSViewMaxYMargin];
	
	tbCornerLeft = [[NSImage imageNamed:@"titlebar-corner-left.png"] retain];
	tbCornerRight= [[NSImage imageNamed:@"titlebar-corner-right.png"] retain];
	tbMiddle = [[NSImage imageNamed:@"titlebar-middle.png"] retain];
}

- (void)drawRect:(NSRect)dirtyRect
{	
	NSSize leftSize = [tbCornerLeft size];
	NSSize rightSize = [tbCornerRight size];
	NSSize titleSize = [self bounds].size;
	NSPoint drawPos;
	
	drawPos.x = 0;
	drawPos.y = 0;
	
	dirtyRect.origin.x = 0;
	dirtyRect.origin.y = 0;
	
	//dirtyRect.size = titleSize;
	//[[NSColor whiteColor] set];
	//	NSRectFill(dirtyRect);

	dirtyRect.size = leftSize;
	[tbCornerLeft drawAtPoint:drawPos fromRect:dirtyRect operation:NSCompositeCopy fraction:1.0];
	
	drawPos.x = titleSize.width - rightSize.width;
	dirtyRect.size = rightSize;
	[tbCornerRight drawAtPoint:drawPos fromRect:dirtyRect operation:NSCompositeCopy fraction:1.0];
	
	dirtyRect.size = [tbMiddle size];
	[tbMiddle drawInRect:NSMakeRect(leftSize.width, 0, titleSize.width-leftSize.width-rightSize.width, titleSize.height)
				fromRect:dirtyRect
			   operation:NSCompositeCopy
				fraction:1.0];

	if (title) {
		NSAttributedString *t = [[NSAttributedString alloc] initWithString:title attributes:titleAttr];
		dirtyRect.size = [t size];
		
		drawPos.x = MAX(64, (titleSize.width -dirtyRect.size.width)/2);
		drawPos.y = (titleSize.height - dirtyRect.size.height)/2;
		
		[t drawAtPoint: drawPos];
		[t release];
	}
}


-(void) applicationWillBecomeActive:(NSNotification*) notif
{
	[closeButton setEnabled:YES];
	[miniButton setEnabled:YES];
	[zoomButton setEnabled:YES];
}

-(void) applicationWillResignActive:(NSNotification*) notif
{
	[closeButton setEnabled:NO];
	[miniButton setEnabled:NO];
	[zoomButton setEnabled:NO];
}

@end
