//
//  InsideJobAppDelegate.m
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "InsideJobAppDelegate.h"
#import "IJMinecraftLevel.h"

NSString * const IJKeyURL = @"IJKeyURL";
NSString * const IJKeyName = @"IJKeyName";

@interface InsideJobAppDelegate ()
- (void)updateWorldsList;
- (IBAction)worldChooserTableSelectionChanged:(id)sender;
@end

@implementation InsideJobAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[worldChooserTable setDoubleAction:@selector(openWorld:)];
	[worldChooserTable setTarget:self];
	[self updateWorldsList];
	[self worldChooserTableSelectionChanged:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyWindowWillClose:) name:NSWindowWillCloseNotification object:nil];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}

- (NSString *)nameAndVersion
{
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	return [NSString stringWithFormat:@"%@ %@",
			[info objectForKey:(id)kCFBundleNameKey],
			[info objectForKey:@"CFBundleShortVersionString"],
			nil];
}

- (void)updateWorldsList
{
	if (!worlds)
		worlds = [[NSMutableArray alloc] init];
	[worlds removeAllObjects];
	for (NSURL *url in [IJMinecraftLevel minecraftLevelURLs])
	{
		NSData *fileData = [NSData dataWithContentsOfURL:url];
		IJMinecraftLevel *level = [IJMinecraftLevel nbtContainerWithData:fileData];

		NSString *name = [level levelName];
		if (!name)
			name = [[url URLByDeletingLastPathComponent] lastPathComponent];
		
		NSDictionary *world = [NSDictionary dictionaryWithObjectsAndKeys:
							   url, IJKeyURL,
							   name, IJKeyName,
							   nil];
		[worlds addObject:world];
	}
	[worlds sortUsingComparator:^(id a, id b) {
		return (NSComparisonResult)[[a objectForKey:IJKeyName] compare:[b objectForKey:IJKeyName]];
	}];
	[worldChooserTable reloadData];
}

- (void)openWorldAtIndex:(NSUInteger)index
{
	NSURL *url = [[worlds objectAtIndex:index] objectForKey:IJKeyURL];
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:nil];
}

- (void)updateWorldChooserWindowShown
{
	int openDocuments = [[[NSDocumentController sharedDocumentController] documents] count];
	if (openDocuments > 0)
		[worldChooserWindow orderOut:nil];
	else
		[worldChooserWindow orderFront:nil];
}

#pragma mark -
#pragma mark Menu Delegate

- (NSInteger)numberOfItemsInMenu:(NSMenu*)menu
{
	[self updateWorldsList];
	return [worlds count];
}

- (BOOL)menu:(NSMenu*)menu updateItem:(NSMenuItem*)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
	[item setTitle:[[worlds objectAtIndex:index] objectForKey:IJKeyName]];
	[item setTag:index];
	[item setTarget:self];
	[item setAction:@selector(openMenuWorld:)];
	return YES;
}

- (void)openMenuWorld:(id)sender
{
	NSUInteger index = [sender tag];
	[self openWorldAtIndex:index];
}

#pragma mark -
#pragma mark World Chooser

- (IBAction)openWorld:(id)sender
{
	NSUInteger index = [worldChooserTable selectedRow];
	[self openWorldAtIndex:index];
	[self updateWorldChooserWindowShown];
}

- (IBAction)worldChooserTableSelectionChanged:(id)sender
{
	[openButton setEnabled:[worldChooserTable selectedRow] != -1];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [worlds count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [[worlds objectAtIndex:row] objectForKey:IJKeyName];
}

- (void)notifyWindowWillClose:(NSNotification *)notification
{
	// Check after a short delay because the document is still open:
	[self performSelector:@selector(updateWorldChooserWindowShown) withObject:nil afterDelay:0.1];
}

@end
