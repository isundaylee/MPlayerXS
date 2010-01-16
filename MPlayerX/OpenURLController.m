/*
 * MPlayerX - OpenURLController.m
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
#import "OpenURLController.h"
#import "PlayerController.h"

@implementation OpenURLController

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithBool:YES], kUDKeyDebugEnableOpenURL,
	  nil]];
}

-(IBAction) openURL:(id) sender
{
	if ([NSApp runModalForWindow:openURLPanel] == NSFileHandlingPanelOKButton) {
		NSString *urlString = [urlBox stringValue];
		
		if (![[urlBox objectValues] containsObject:urlString]) {
			// 将这个URL添加到list中
			[urlBox addItemWithObjectValue:urlString];
		}
		// 现在mplayer的在线播放的功能不是很稳定，经常freeze，因此先禁用这个功能
		if ([[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyDebugEnableOpenURL]) {
			[playerController loadFiles:[NSArray arrayWithObject:urlString] fromLocal:NO];
		}
	}
}

-(IBAction) confirmed:(id) sender
{
	NSURL *url = [NSURL URLWithString:[urlBox stringValue]];
	
	if ([[url scheme] caseInsensitiveCompare:@"http"] == NSOrderedSame || [[url scheme] caseInsensitiveCompare:@"ftp"] == NSOrderedSame ||
		[[url scheme] caseInsensitiveCompare:@"rtsp"] == NSOrderedSame || [[url scheme] caseInsensitiveCompare:@"mms"] == NSOrderedSame) {
		// 先修正URL
		[urlBox setStringValue:[[url standardizedURL] absoluteString]];
		// 退出Modal模式
		[NSApp stopModalWithCode:NSFileHandlingPanelOKButton];
		// 隐藏窗口
		[openURLPanel orderOut:self];
	} else {
		NSBeginAlertSheet(NSLocalizedString(@"Error", nil), NSLocalizedString(@"OK", nil), nil, nil, openURLPanel, nil, nil, nil, nil, NSLocalizedString(@"The URL is unsupported by MPlayerX.", nil));
	}
}

-(IBAction) canceled:(id) sender
{
	[NSApp abortModal];
	[openURLPanel orderOut:self];
}

@end
