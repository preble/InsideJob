//
//  InsideJobAppDelegate.m
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "InsideJobAppDelegate.h"
#import "NBTContainer.h"
#import "IJMinecraftLevel.h"

@implementation InsideJobAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
	NSData *fileData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"../../world5-level.dat"]];
	IJMinecraftLevel *level = [IJMinecraftLevel nbtContainerWithData:fileData];
	[level inventory];
	
//	NSData *newData = [level writeData];
//	[newData writeToURL:[NSURL fileURLWithPath:@"../../output.nbt"] atomically:NO];
}

@end
