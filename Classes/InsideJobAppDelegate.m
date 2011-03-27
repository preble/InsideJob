//
//  InsideJobAppDelegate.m
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "InsideJobAppDelegate.h"
#import "IJMinecraftLevel.h"

@implementation InsideJobAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}

#pragma mark -
#pragma mark Menu Delegate

//- (void)menuNeedsUpdate:(NSMenu*)menu
//{
//}

- (NSInteger)numberOfItemsInMenu:(NSMenu*)menu
{
	[menuWorldURLs release];
	menuWorldURLs = [[IJMinecraftLevel minecraftLevelURLs] retain];
	return [menuWorldURLs count];
}

- (BOOL)menu:(NSMenu*)menu updateItem:(NSMenuItem*)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
	NSURL *url = [menuWorldURLs objectAtIndex:index];
	[item setTitle:[NSString stringWithFormat:@"%@", [[url URLByDeletingLastPathComponent] lastPathComponent]]];
	[item setTag:index];
	[item setTarget:self];
	[item setAction:@selector(openMenuWorld:)];
	return YES;
}

- (void)openMenuWorld:(id)sender
{
	NSUInteger index = [sender tag];
	NSURL *url = [menuWorldURLs objectAtIndex:index];
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:nil];
}

@end
