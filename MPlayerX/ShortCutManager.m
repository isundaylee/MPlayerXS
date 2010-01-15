/*
 * MPlayerX - ShortCutManager.m
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
#import "ShortCutManager.h"
#import "PlayerController.h"
#import "ControlUIView.h"
#import "RootLayerView.h"

@implementation ShortCutManager

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithFloat:0.1], kUDKeySpeedStep,
					   [NSNumber numberWithFloat:10], kUDKeySeekStepLR,
					   [NSNumber numberWithFloat:60], kUDKeySeekStepUB,
					   [NSNumber numberWithFloat:0.1], kUDKeySubDelayStepTime,
					   [NSNumber numberWithFloat:0.1], kUDKeyAudioDelayStepTime,
					   nil]];
}

-(id) init
{
	if (self = [super init]) {
		ud = [NSUserDefaults standardUserDefaults];
		
		speedStepIncre = [ud floatForKey:kUDKeySpeedStep];
		seekStepTimeLR = [ud floatForKey:kUDKeySeekStepLR];
		seekStepTimeUB = [ud floatForKey:kUDKeySeekStepUB];
		appleRemoteControl = [[AppleRemote alloc] initWithDelegate:self];
		subDelayStepTime = [ud floatForKey:kUDKeySubDelayStepTime];
		audioDelayStepTime = [ud floatForKey:kUDKeyAudioDelayStepTime];
	}
	return self;
}

-(void) awakeFromNib
{


	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationWillBecomeActive:)
												 name:NSApplicationWillBecomeActiveNotification
											   object:NSApp];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationWillResignActive:)
												 name:NSApplicationWillResignActiveNotification
											   object:NSApp];
}

-(void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[appleRemoteControl release];

	[super dealloc];
}

-(BOOL) processKeyDown:(NSEvent*) event
{
	unichar key;
	BOOL ret = YES;
	
	// 这里处理的是没有keyequivalent的快捷键
	if ([[event charactersIgnoringModifiers] length] == 0) {
		ret = NO;
	} else {
		key = [[event charactersIgnoringModifiers] characterAtIndex:0];

		switch ([event modifierFlags] & (NSShiftKeyMask| NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask))
		{
			case NSControlKeyMask:
				switch (key)
				{
					case NSUpArrowFunctionKey:
						[playerController changeSpeedBy:speedStepIncre];
						break;
					case NSDownArrowFunctionKey:
						[playerController changeSpeedBy:-speedStepIncre];
						break;
					case NSLeftArrowFunctionKey:
						[playerController setSpeed:1];
						break;
					default:
						ret = NO;
						break;
				}
				break;
				
			case NSShiftKeyMask:
				switch (key)
				{
					default:
						ret = NO;
						break;
				}
				break;
			case NSAlternateKeyMask:
				switch (key)
				{
					case NSUpArrowFunctionKey:
						[playerController changeAudioDelayBy:audioDelayStepTime];
						break;
					case NSDownArrowFunctionKey:
						[playerController changeAudioDelayBy:-audioDelayStepTime];
						break;
					case NSLeftArrowFunctionKey:
						[playerController setAudioDelay:0];
						break;
					default:
						ret = NO;
						break;
				}
				break;

			case NSCommandKeyMask:		//按下CMD键
				switch (key)
				{
					case NSUpArrowFunctionKey:
						[playerController changeSubDelayBy:subDelayStepTime];
						break;
					case NSDownArrowFunctionKey:
						[playerController changeSubDelayBy:-subDelayStepTime];
						break;
					case NSLeftArrowFunctionKey:
						[playerController setSubDelay:0];
						break;
					default:
						ret = NO;
						break;
				}
				break;
			case 0:				// 什么功能键也没有按
				switch (key)
				{
					case NSRightArrowFunctionKey:
						[controlUI changeTimeBy:seekStepTimeLR];
						break;
					case NSLeftArrowFunctionKey:
						[controlUI changeTimeBy:-seekStepTimeLR];
						break;
					case NSUpArrowFunctionKey:
						[controlUI changeTimeBy:seekStepTimeUB];
						break;
					case NSDownArrowFunctionKey:
						[controlUI changeTimeBy:-seekStepTimeUB];
						break;
					default:
						ret = NO;
						break;
				}
				break;
			default:
				ret = NO;
				break;
		}
	}
	return ret;
}

#define kSCMTypeKeyEquivalent	(1)
#define kSCMTypeKeyDownEvent	(-1)
#define kSCMTypeNone			(0)

- (void) sendRemoteButtonEvent: (RemoteControlEventIdentifier) event pressedDown: (BOOL) pressedDown remoteControl: (RemoteControl*) remoteControl
{
	unichar key = 0;
	int type = kSCMTypeNone;
	NSString *keyEqTemp = nil;
	id keyEquivalentHolder = controlUI;

	if (pressedDown) {
		switch(event) {
			case kRemoteButtonPlus:
				keyEqTemp = kSCMVolumeUpKeyEquivalent;
				type = kSCMTypeKeyEquivalent;
				keyEquivalentHolder = mainMenu;
				break;
			case kRemoteButtonMinus:
				keyEqTemp = kSCMVolumeDownKeyEquivalent;
				type = kSCMTypeKeyEquivalent;
				keyEquivalentHolder = mainMenu;
				break;			
			case kRemoteButtonMenu:
				keyEqTemp = kSCMFullScrnKeyEquivalent;
				type = kSCMTypeKeyEquivalent;
				break;			
			case kRemoteButtonPlay:
				keyEqTemp = kSCMPlayPauseKeyEquivalent;
				type = kSCMTypeKeyEquivalent;
				break;			
			case kRemoteButtonRight:
				key = NSRightArrowFunctionKey;
				type = kSCMTypeKeyDownEvent;
				break;			
			case kRemoteButtonLeft:
				key = NSLeftArrowFunctionKey;
				type = kSCMTypeKeyDownEvent;
				break;			
			case kRemoteButtonRight_Hold:
				key = NSUpArrowFunctionKey;
				type = kSCMTypeKeyDownEvent;
				break;	
			case kRemoteButtonLeft_Hold:
				key = NSDownArrowFunctionKey;
				type = kSCMTypeKeyDownEvent;
				break;			
			case kRemoteButtonPlus_Hold:
				break;				
			case kRemoteButtonMinus_Hold:
				break;				
			case kRemoteButtonPlay_Hold:
				break;			
			case kRemoteButtonMenu_Hold:
				keyEqTemp = kSCMFillScrnKeyEquivalent;
				type = kSCMTypeKeyEquivalent;
				break;
			case kRemoteControl_Switched:
				break;
			default:
				type = kSCMTypeNone;
				break;
		}
		if (kSCMTypeKeyDownEvent == type) {
			[self processKeyDown:[NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0, 0) modifierFlags:0 timestamp:0
											  windowNumber:0 context:nil
												characters:nil
							   charactersIgnoringModifiers:[NSString stringWithCharacters:&key length:1]
												 isARepeat:NO keyCode:0]];
			
		} else if (kSCMTypeKeyEquivalent == type) {
			[keyEquivalentHolder performKeyEquivalent:[NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0, 0) modifierFlags:0 timestamp:0
																   windowNumber:0 context:nil
																	 characters:keyEqTemp
													charactersIgnoringModifiers:keyEqTemp
																	  isARepeat:NO keyCode:0]];			
		}			
	}
}

-(void) applicationWillBecomeActive:(NSNotification*) notif
{
	[appleRemoteControl startListening:self];
}

-(void) applicationWillResignActive:(NSNotification*) notif
{
	[appleRemoteControl stopListening:self];
}

@end
