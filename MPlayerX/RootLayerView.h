/*
 * MPlayerX - RootLayerView.h
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
#import "CoreController.h"

@class ControlUIView, PlayerController, ShortCutManager, DisplayLayer;

@interface RootLayerView : NSView <CoreDisplayDelegate>
{
	NSUserDefaults *ud;

	NSTrackingArea *trackingArea;

	BOOL shouldResize;
	DisplayLayer *dispLayer;
	
	BOOL displaying;
	NSDictionary *fullScreenOptions;
	CGDirectDisplayID fullScrnDevID;
	
	IBOutlet ControlUIView *controlUI;
	IBOutlet PlayerController *playerController;
	IBOutlet ShortCutManager *shortCutManager;
}

@property (readonly) CGDirectDisplayID fullScrnDevID;

-(void) setPlayerWindowLevel;

-(BOOL) toggleFullScreen;
-(BOOL) toggleFillScreen;

-(int) startWithWidth:(int) width height:(int) height pixelFormat:(OSType) pixelFormat aspect:(int) aspect from:(id)sender;
-(void) draw:(void*)imageData from:(id)sender;
-(void) stop:(id)sender;

-(IBAction) writeSnapshotToFile:(id)sender;

@end
