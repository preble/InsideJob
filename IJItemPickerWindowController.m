//
//  IJItemPickerWindowController.m
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJItemPickerWindowController.h"
#import "IJInventoryItem.h"

@implementation IJItemPickerWindowController

@synthesize tableView;

+ (IJItemPickerWindowController *)sharedController
{
	static IJItemPickerWindowController *globalSharedController = nil;
	if (!globalSharedController)
	{
		globalSharedController = [[IJItemPickerWindowController alloc] initWithWindowNibName:@"ItemPicker"];
	}
	return globalSharedController;
}

- (void)awakeFromNib
{
	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(itemActivated:)];
	
	NSArray *keys = [[IJInventoryItem itemIdLookup] allKeys];
	keys = [keys sortedArrayUsingSelector:@selector(compare:)];
	allItemIds = [[NSArray alloc] initWithArray:keys];
	filteredItemIds = [allItemIds retain];
}

- (void)showPickerWithInitialItemId:(uint16_t)initialItemId completionBlock:(void(^)(uint16_t itemId))theBlock
{
	[self showWindow:nil];
	
	[completionBlock autorelease];
	completionBlock = [theBlock copy];
	
	NSUInteger row = [filteredItemIds indexOfObject:[NSNumber numberWithShort:initialItemId]];
	if (row != NSNotFound)
	{
		[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		[tableView scrollRowToVisible:row];
	}
}

- (IBAction)updateFilter:(id)sender
{
	NSString *filterString = [sender stringValue];
	
	if (filterString.length == 0)
	{
		[filteredItemIds autorelease];
		filteredItemIds = [allItemIds retain];
		[tableView reloadData];
		return;
	}
	
	NSMutableArray *results = [NSMutableArray array];
	
	for (NSNumber *itemId in allItemIds)
	{
		NSString *name = [[IJInventoryItem itemIdLookup] objectForKey:itemId];
		NSRange range = [name rangeOfString:filterString options:NSCaseInsensitiveSearch];
		if (range.location != NSNotFound)
			[results addObject:itemId];
	}
	
	[filteredItemIds autorelease];
	filteredItemIds = [results retain];
	[tableView reloadData];
}

- (IBAction)itemActivated:(id)sender
{
	NSUInteger row = [tableView selectedRow];
	uint16_t itemId = [[filteredItemIds objectAtIndex:row] shortValue];
	
	[[self window] orderOut:nil];
	
	completionBlock(itemId);
}

#pragma mark -
#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView
{
	return filteredItemIds.count;
}
- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	// TODO: Change this, because the row will not correspond once we support sorting.
	NSNumber *itemId = [filteredItemIds objectAtIndex:row];
	
	if ([tableColumn.identifier isEqual:@"itemId"])
		return [itemId stringValue];
		
	NSString *name = [[IJInventoryItem itemIdLookup] objectForKey:itemId];
	return name;
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	[[self window] orderOut:nil];
}

@end
