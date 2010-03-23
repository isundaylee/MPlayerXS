/*
 * MPlayerX - ShortCutManager.m
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

#import "def.h"
#import "ShortCutManager.h"
#import "PlayerController.h"
#import "ControlUIView.h"
#import "RootLayerView.h"
#import "AppleRemote.h"

#define kSCMRepeatCounterThreshold	(6)

@interface ShortCutManager (ShortCutManagerInternal)
-(void)simulateEvent:(NSArray*) arg;
@end

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
					   [NSNumber numberWithFloat:0.3], kUDKeyARKeyRepeatTimeInterval,
					   [NSNumber numberWithFloat:1.0], kUDKeyARKeyRepeatTimeIntervalLong,
					   nil]];
}

-(id) init
{
	if (self = [super init]) {
		ud = [NSUserDefaults standardUserDefaults];
		
		speedStepIncre = [ud floatForKey:kUDKeySpeedStep];
		seekStepTimeLR = [ud floatForKey:kUDKeySeekStepLR];
		seekStepTimeUB = [ud floatForKey:kUDKeySeekStepUB];
		subDelayStepTime = [ud floatForKey:kUDKeySubDelayStepTime];
		audioDelayStepTime = [ud floatForKey:kUDKeyAudioDelayStepTime];
		arKeyRepTime = [ud floatForKey:kUDKeyARKeyRepeatTimeInterval];

		repeatEntered = NO;
		repeatCanceled = NO;
		repeatCounter = 0;
		
		appleRemoteControl = [[AppleRemote alloc] initWithDelegate:self];		
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
					case kSCMFullScrnShortcutKey:
						[controlUI performKeyEquivalent:[NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0, 0) modifierFlags:0 timestamp:0
																	 windowNumber:0 context:nil
																	   characters:kSCMFullScrnKeyEquivalent
													  charactersIgnoringModifiers:kSCMFullScrnKeyEquivalent
																		isARepeat:NO keyCode:0]];
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
					case kSCMPlaybackSpeedUpShortcutKey:
						[playerController changeSpeedBy:speedStepIncre];
						break;
					case kSCMPlaybackSpeedDownShortcutKey:
						[playerController changeSpeedBy:-speedStepIncre];
						break;
					case kSCMAudioDelayPlusShortcutKey:
						[playerController changeAudioDelayBy:audioDelayStepTime];
						break;
					case kSCMAudioDelayMinusShortcutKey:
						[playerController changeAudioDelayBy:-audioDelayStepTime];
						break;
					case kSCMSubDelayPlusShortcutKey:
						[playerController changeSubDelayBy:subDelayStepTime];
						break;
					case kSCMSubDelayMinusShortcutKey:
						[playerController changeSubDelayBy:-subDelayStepTime];
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

-(void) sendRemoteButtonEvent:(RemoteControlEventIdentifier)event pressedDown:(BOOL)pressedDown remoteControl:(RemoteControl*)remoteControl
{
	unichar key = 0;
	NSString *keyEqTemp = nil;
	id target = nil;
	SEL action = NULL;
	
	if (pressedDown) {
		repeatCanceled = NO;
		// 如果是按下键
		switch(event) {
			case kRemoteButtonPlus_Hold:
			case kRemoteButtonPlus:
				keyEqTemp = kSCMVolumeUpKeyEquivalent;
				target = mainMenu;
				action = @selector(performKeyEquivalent:);
				break;
				
			case kRemoteButtonMinus_Hold:
			case kRemoteButtonMinus:
				keyEqTemp = kSCMVolumeDownKeyEquivalent;
				target = mainMenu;
				action = @selector(performKeyEquivalent:);
				break;			
						
			case kRemoteButtonMenu:
				keyEqTemp = kSCMFullScrnKeyEquivalent;
				target = controlUI;
				action = @selector(performKeyEquivalent:);
				break;			
			
			case kRemoteButtonMenu_Hold:
				keyEqTemp = kSCMFillScrnKeyEquivalent;
				target = controlUI;
				action = @selector(performKeyEquivalent:);
				break;
			
			case kRemoteButtonPlay:
				keyEqTemp = kSCMPlayPauseKeyEquivalent;
				target = controlUI;
				action = @selector(performKeyEquivalent:);
				break;			
			
			case kRemoteButtonRight_Hold:
				repeatEntered = YES;
				repeatCounter = 0;
				arKeyRepTime = [ud floatForKey:kUDKeyARKeyRepeatTimeInterval];
			case kRemoteButtonRight:
				key = NSRightArrowFunctionKey;
				target = self;
				action = @selector(processKeyDown:);
				break;			
						
			case kRemoteButtonLeft_Hold:
				repeatEntered = YES;
				repeatCounter = 0;
				arKeyRepTime = [ud floatForKey:kUDKeyARKeyRepeatTimeInterval];
			case kRemoteButtonLeft:
				key = NSLeftArrowFunctionKey;
				target = self;
				action = @selector(processKeyDown:);
				break;			
			
			default:
				break;
		}
		if (target && action) {
			NSEvent *event;
			if (keyEqTemp) {
				event = [NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0, 0) modifierFlags:0 timestamp:0
									 windowNumber:0 context:nil
									   characters:keyEqTemp
					  charactersIgnoringModifiers:keyEqTemp
										isARepeat:NO keyCode:0];
			} else {
				event = [NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0, 0) modifierFlags:0 timestamp:0
									 windowNumber:0 context:nil
									   characters:[NSString stringWithCharacters:&key length:1]
					  charactersIgnoringModifiers:[NSString stringWithCharacters:&key length:1]
										isARepeat:NO keyCode:0];
			}
			[self simulateEvent:[NSArray arrayWithObjects:target, [NSNumber numberWithInteger:((NSInteger)action)], event, nil]];
		}		
	} else {
		// 如果是放开键
		repeatCanceled = YES;
		repeatEntered = NO;
	}

}

-(void) simulateEvent:(NSArray *)arg
{
	id tgt = [arg objectAtIndex:0];
	SEL sel = (SEL)[[arg objectAtIndex:1] integerValue];
	NSEvent *evt = [arg objectAtIndex:2];
	
	if (!repeatCanceled) {
		[tgt performSelector:sel withObject:evt];
	}
	
	if (repeatEntered) {		
		repeatCounter++;
		
		if (repeatCounter != kSCMRepeatCounterThreshold) {
			[self performSelector:@selector(simulateEvent:) withObject:arg afterDelay:arKeyRepTime];
			
		} else if (repeatCounter == kSCMRepeatCounterThreshold) {
			NSEvent *newEv = nil;
			unichar key = [[evt charactersIgnoringModifiers] characterAtIndex:0];
			float timeLong = arKeyRepTime;
			
			if ((key == NSRightArrowFunctionKey) || (key == NSLeftArrowFunctionKey)) {
				if (key == NSRightArrowFunctionKey) {
					key = NSUpArrowFunctionKey;
				} else {
					key = NSDownArrowFunctionKey;
				}
				newEv = [NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0, 0) modifierFlags:0 timestamp:0
									 windowNumber:0 context:nil
									   characters:[NSString stringWithCharacters:&key length:1]
					  charactersIgnoringModifiers:[NSString stringWithCharacters:&key length:1]
										isARepeat:NO keyCode:0];
				timeLong = [ud floatForKey:kUDKeyARKeyRepeatTimeIntervalLong];
			} else {
				newEv = evt;
			}
			
			[self performSelector:@selector(simulateEvent:)
					   withObject:[NSArray arrayWithObjects:tgt, [NSNumber numberWithInteger:((NSInteger)sel)], newEv, nil]
					   afterDelay:arKeyRepTime];
			arKeyRepTime = timeLong;
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
