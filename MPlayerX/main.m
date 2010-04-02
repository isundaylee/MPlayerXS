/*
 * MPlayerX - main.m
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

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	int ret;

#ifdef MPX_DEBUG
	NSString *home = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *logDir = [[NSString alloc] initWithFormat:@"%@/Logs", home];
	NSString *logPath = [[NSString alloc] initWithFormat:@"%@/MPlayerX.log",logDir];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	if (![fm fileExistsAtPath:logDir]) {
		// log folder does not exist
		[fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	if ([fm fileExistsAtPath:logPath] &&
		[[[fm attributesOfItemAtPath:logPath error:NULL] objectForKey:NSFileSize] unsignedLongLongValue] > 100000) {
		[fm removeItemAtPath:logPath error:NULL];
	}

	int stderrRes = dup(STDERR_FILENO);
	FILE *logFile = freopen([logPath UTF8String], "a", stderr);
	[logPath release];
	[logDir release];
#endif // MPX_DEBUG
	
    ret =  NSApplicationMain(argc,  (const char **) argv);
#ifdef MPX_DEBUG
	fflush(logFile);
	dup2(stderrRes, STDERR_FILENO);
	fclose(logFile);
#endif //MPX_DEBUG
	return ret;
}
