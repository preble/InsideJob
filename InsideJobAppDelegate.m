//
//  InsideJobAppDelegate.m
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "InsideJobAppDelegate.h"
#import "NBTContainer.h"

@implementation InsideJobAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
	NSData *fileData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"../../level.dat"]];
	NBTContainer *nbtFile = [NBTContainer nbtContainerWithData:fileData];
}

@end
