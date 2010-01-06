//
//  ResizeIndicator.m
//  MPlayerX
//
//  Created by 瞿 宗耀 on 10-1-6.
//  Copyright 2010 MPlayerX. All rights reserved.
//

#import "ResizeIndicator.h"


@implementation ResizeIndicator

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        im = nil;
    }
    return self;
}

-(void) awakeFromNib
{
	im = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"resizeindicator.png"]];
	imRect = NSMakeRect(0, 0, [im size].width, [im size].height);
}

- (void)drawRect:(NSRect)dirtyRect
{
	[im drawAtPoint:NSMakePoint(0, 0) fromRect:imRect operation:NSCompositeCopy fraction:1];
}

@end
