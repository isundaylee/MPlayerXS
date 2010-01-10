/*
 * MPlayerX - ShortCutManager.h
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
#import "AppleRemote.h"

@class AppController, ControlUIView, RootLayerView;

@interface ShortCutManager : NSObject
{
	AppleRemote *appleRemoteControl;
	
	float speedStepIncre;
	float seekStepTimeLR;
	float seekStepTimeUB;
	float subDelayStepTime;
	float audioDelayStepTime;

	IBOutlet AppController *appController;
	IBOutlet ControlUIView *controlUI;
	IBOutlet RootLayerView *dispView;
	IBOutlet NSMenu *mainMenu;
}

-(BOOL) processKeyDown:(NSEvent*) event;


- (void) sendRemoteButtonEvent: (RemoteControlEventIdentifier) event pressedDown: (BOOL) pressedDown remoteControl: (RemoteControl*) remoteControl;

@end
