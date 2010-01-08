/*
 * MPlayerX - PlayerCore.m
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
#import "PlayerCore.h"

/** 默认的stdout，stderr的polling时间间隔*/
#define POLLING_TIME	(0.5)

// 内部category
@interface PlayerCore (PlayerCoreInternal)
-(void) taskHasTerminated;
-(void) readOutput:(NSNotification *)notification;
-(void) readError:(NSNotification *)notification;
-(void) pollingOutputAndError;
-(void) playMediaPlayerThread:(NSArray*) args;
-(void) releaseTimerAndRemoveObserverOnPlayerThread;
@end


@implementation PlayerCore

@synthesize delegate;

#pragma mark Init/Dealloc
-(id) init 
{
	if (self = [super init]) {
		delegate = nil;
		task = nil;
		pollingTimer = nil;
		playThread = nil;
	}
	return self;
}

-(void) dealloc
{
	[self terminate];
	[super dealloc];
}

#pragma mark Function
-(void) releaseTimerAndRemoveObserverOnPlayerThread
{
	// 在工作线程上建立的Timer，因此必须在工作线程上销毁
	if (pollingTimer) {
		[pollingTimer invalidate];
		[pollingTimer release];
		pollingTimer = nil;
	}
	// 这里的消息监听是建立在工作线程上的，因此必须在工作线程上销毁
	// 有可能会多次运行，但是没有关系
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) terminate
{
	if (task) { // 如果task没有被销毁
		if (playThread) {
			[self performSelector:@selector(releaseTimerAndRemoveObserverOnPlayerThread)
						 onThread:playThread
					   withObject:nil
					waitUntilDone:YES];

			[playThread cancel];
			[playThread release];
			playThread = nil;
		}

		if ([task isRunning]) {
			[task terminate];
			[task waitUntilExit];
			[task release];
			task = nil;
			
			if (delegate) {
				[delegate playerTaskTerminated:YES from:self];
			}
		} else {
			[task release];
			task = nil;
		}
	}
}

- (BOOL) playMedia: (NSString *) moviePath withExec: (NSString *) execPath withParams: (NSArray *) params
{
	if (moviePath && execPath) {
		[self terminate];
		
		playThread = [[NSThread alloc] initWithTarget:self 
											 selector:@selector(playMediaPlayerThread:)
											   object:[NSArray arrayWithObjects:moviePath, execPath, params,nil]];
		[playThread start];
		return YES;
	}
	return NO;
}

- (void) playMediaPlayerThread:(NSArray*) args
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *moviePath = [args objectAtIndex:0];
	NSString *execPath = [args objectAtIndex:1];
	NSArray *params = [args objectAtIndex:2];
	
	NSRunLoop *runloop = [NSRunLoop currentRunLoop];
	
	NSMutableDictionary *env;
	
	// 建立task
	task = [[NSTask alloc] init];
	// 关联输入输出
	[task setStandardInput:[NSPipe pipe]];
	[task setStandardOutput:[NSPipe pipe]];
	[task setStandardError: [NSPipe pipe]];
	// 指定运行exec的地址
	[task setLaunchPath: execPath];
	// 创建argv
	if (params) {
		[task setArguments: [params arrayByAddingObject:moviePath]];
	} else {
		[task setArguments: [NSArray arrayWithObject:moviePath]];
	}
	
	// 设置环境参数
	env = [[[NSProcessInfo processInfo] environment] mutableCopy];
	[env setObject:@"1" forKey:@"DYLD_BIND_AT_LAUNCH"]; //delete the message for DYLD
	[env setObject:@"xterm" forKey:@"TERM"]; // delete the message from mplayer about the "unknown" terminal
	[task setEnvironment:env];
	[env autorelease];
	
	[task setCurrentDirectoryPath:[execPath stringByDeletingLastPathComponent]];
	
	// 建立监听机制
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(readOutput:)
												 name:NSFileHandleReadCompletionNotification
											   object:[[task standardOutput] fileHandleForReading]];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(readError:)
												 name:NSFileHandleReadCompletionNotification
											   object:[[task standardError] fileHandleForReading]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(taskHasTerminated)
												 name:NSTaskDidTerminateNotification
											   object:task];
	
	pollingTimer = [[NSTimer scheduledTimerWithTimeInterval:POLLING_TIME
													 target:self
												   selector:@selector(pollingOutputAndError)
												   userInfo:nil
													repeats:YES] retain];
	// 运行task
	[task launch];
	[runloop run];
	
	[pool release];
}

-(void) pollingOutputAndError
{
	if (task && [task isRunning]) {
		[[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
		[[[task  standardError] fileHandleForReading] readInBackgroundAndNotify];
	}
}


- (BOOL) sendStringCommand: (NSString *) cmd
{
	// 如果task正在运行
	if (task && [task isRunning]) {
		// 以防万一，在命令后面加一个回车
		[[[task standardInput] fileHandleForWriting] writeData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
		return YES;
	}
	return NO;
}

#pragma mark Internal 
- (void) readOutput:(NSNotification *)notification
{
	NSData *data = [[notification userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
	
	if (task && [task isRunning] && ([data length] != 0)) {
		if (delegate) {
			[delegate outputAvailable:data from:self];
		}
	}
}

- (void) readError:(NSNotification *)notification
{
	NSData *data = [[notification userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
	
	if (task && [task isRunning] && ([data length] != 0)) {
		if (delegate) {
			[delegate errorHappened:data from:self];
		}
	}
}

// 这个代码发生在Player线程
- (void) taskHasTerminated
{
	// 这里不能销毁PlayerThread主体，因为这段代码本身就是在PlayerThread中运行的。
	// 而这里并没有销毁task，所以在下一次playMedia或者dealloc的时候，会因为terminate task而释放PlayerThread
	[self performSelector:@selector(releaseTimerAndRemoveObserverOnPlayerThread) onThread:playThread withObject:nil waitUntilDone:YES];

	// 这里应该不能加别的清理工作，这个方法是在 副线程上激发的
	// 而在terminate方法里面也包括了清理副线程的代码，可能会引发crash
	// [self terminate];
	if (delegate) {
		[delegate playerTaskTerminated:NO from:self];
	}
}

@end
