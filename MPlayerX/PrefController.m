/*
 * MPlayerX - PrefController.m
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
#import "PrefController.h"
#import "AppController.h"
#import "RootLayerView.h"
#import "ControlUIView.h"

#define PrefToolBarItemIdGeneral	(@"TBIGeneral")
#define PrefToolBarItemIdDisplay	(@"TBIDisplay")

#define PrefTBILabelGeneral			(@"General")
#define PrefTBILabelDisplay			(@"Display")

@implementation PrefController

@synthesize prefWin;

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithInt:0], kUDKeySelectedPrefView,
	  nil]];
}

-(id) init
{
	if (self = [super init]) {
		nibLoaded = NO;
		prefViews = nil;
	}
	return self;
}

-(IBAction) showUI:(id)sender
{
	if (!nibLoaded) {
		[NSBundle loadNibNamed:@"Pref" owner:self];

		prefViews = [[NSArray alloc] initWithObjects:viewGeneral, viewDisplay, nil];
		
		NSToolbarItem *tbi = [[prefToolbar items] objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kUDKeySelectedPrefView]];
		
		if (tbi) {
			[prefToolbar setSelectedItemIdentifier:[tbi itemIdentifier]];
			
			[self switchViews:tbi];
		}
		nibLoaded = YES;
	}
	[prefWin makeKeyAndOrderFront:nil];
}

-(void) dealloc
{
	[prefViews release];
	[super release];
}

-(IBAction) switchViews:(id)sender
{
	NSView *viewToShow = [prefViews objectAtIndex:[sender tag]];
	
	if (viewToShow && ([prefWin contentView] != viewToShow)) {
		NSRect rc = [prefWin frameRectForContentRect:[viewToShow bounds]];
		NSRect winFrm = [prefWin frame];
		
		rc.origin = winFrm.origin;
		rc.origin.y -= (rc.size.height - winFrm.size.height);
		
		[prefWin setContentView: viewToShow];
		[prefWin setFrame:rc display:YES animate:YES];

		[prefWin setTitle:[sender label]];
		
		[[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:kUDKeySelectedPrefView];
	}
}

- (IBAction)multiThreadChanged:(id)sender
{
	[appController setMultiThreadMode:[[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyEnableMultiThread]];
}

- (IBAction)onTopModeChanged:(id)sender
{
	[dispView setPlayerWindowLevel];
}

- (IBAction)hintTimeModeChanged:(id)sender
{
	[controlUI setHintTimePrsOnAbs:[[NSUserDefaults standardUserDefaults] boolForKey:kUDKeySwitchTimeHintPressOnAbusolute]];
}

/////////////////////////////Toolbar Delegate/////////////////////
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:PrefToolBarItemIdGeneral, PrefToolBarItemIdDisplay, nil];
}
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [self toolbarAllowedItemIdentifiers:toolbar];
}
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [self toolbarAllowedItemIdentifiers:toolbar];
}
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	if ([itemIdentifier isEqualToString:PrefToolBarItemIdGeneral]) {
		[item setLabel:PrefTBILabelGeneral];
		[item setImage:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
		[item setTarget:self];
		[item setAction:@selector(switchViews:)];
		[item setAutovalidates:NO];
		[item setTag:0];
		
	} else if ([itemIdentifier isEqualToString:PrefToolBarItemIdDisplay]) {
		[item setLabel:PrefTBILabelDisplay];
		[item setImage:[NSImage imageNamed:@"toolbar_display"]];
		[item setTarget:self];
		[item setAction:@selector(switchViews:)];
		[item setAutovalidates:NO];
		[item setTag:1];
		
	} else {
		[item release];
		return nil;
	}
	return [item autorelease];
}

@end
