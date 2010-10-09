//
//  IJInventoryWindowController.m
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJInventoryWindowController.h"
#import "IJMinecraftLevel.h"
#import "IJInventoryItem.h"
#import "IJItemPickerWindowController.h"
#import "IJInventoryView.h"

@implementation IJInventoryWindowController

@synthesize outlineView;
@synthesize worldSelectionControl;
@synthesize statusTextField;
@synthesize inventoryView, armorView, quickView;


- (void)awakeFromNib
{
	armorItem = [NSMutableArray array];
	quickItem = [NSMutableArray array];
	inventoryItem = [NSMutableArray array];
	rootItems = [[NSArray alloc] initWithObjects:armorItem, quickItem, inventoryItem, nil];
	statusTextField.stringValue = @"";
	
	[inventoryView setRows:3 columns:9];
	[quickView setRows:1 columns:9];
	[armorView setRows:4 columns:1];
	inventoryView.delegate = self;
	quickView.delegate = self;
	armorView.delegate = self;
}

- (void)dealloc
{
	[inventory release];
	[rootItems release];
	[level release];
	[super dealloc];
}


#pragma mark -
#pragma mark World Selection

- (void)loadWorldAtIndex:(int)worldIndex
{
	[armorItem removeAllObjects];
	[quickItem removeAllObjects];
	[inventoryItem removeAllObjects];
	
	// Reload data here because we have just invalidated all of the items used in the outline view.
	[outlineView reloadData];
	
	
	[self willChangeValueForKey:@"worldTime"];
	[level release];
	level = nil;
	[inventory release];
	inventory = nil;
	[self didChangeValueForKey:@"worldTime"];
	
	
	if (![IJMinecraftLevel worldExistsAtIndex:worldIndex])
	{
		NSBeginCriticalAlertSheet(@"No world exists in that slot.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, @"Please create a new single player world in this slot using Minecraft and try again.");
		return;
	}
	
	sessionLockValue = [IJMinecraftLevel writeToSessionLockAtIndex:worldIndex];
	if (![IJMinecraftLevel checkSessionLockAtIndex:worldIndex value:sessionLockValue])
	{
		NSBeginCriticalAlertSheet(@"Error loading world.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, @"Inside Job was unable obtain the session lock.");
		return;
	}
	
	NSString *levelPath = [IJMinecraftLevel pathForLevelDatAtIndex:worldIndex];
	
	NSData *fileData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:levelPath]];
	
	if (!fileData)
	{
		// Error loading 
		[outlineView reloadData];
		NSBeginCriticalAlertSheet(@"Error loading world.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, @"InsideJob was unable to load the level at %@.", levelPath);
		return;
	}
	
	[self willChangeValueForKey:@"worldTime"];
	
	level = [[IJMinecraftLevel nbtContainerWithData:fileData] retain];
	inventory = [[level inventory] retain];
	
	[self didChangeValueForKey:@"worldTime"];
	
	// Add placeholder inventory items:
	
	for (int i = 0; i < IJInventorySlotQuickLast + 1 - IJInventorySlotQuickFirst; i++)
		[quickItem addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotQuickFirst + i]];
	
	for (int i = 0; i < IJInventorySlotNormalLast + 1 - IJInventorySlotNormalFirst; i++)
		[inventoryItem addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotNormalFirst + i]];
	
	for (int i = 0; i < IJInventorySlotArmorLast + 1 - IJInventorySlotArmorFirst; i++)
		[armorItem addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotArmorFirst + i]];
	
	
	// Overwrite the placeholders with actual inventory:
	
	for (IJInventoryItem *item in inventory)
	{
		if (IJInventorySlotQuickFirst <= item.slot && item.slot <= IJInventorySlotQuickLast)
		{
			[quickItem replaceObjectAtIndex:item.slot - IJInventorySlotQuickFirst withObject:item];
		}
		else if (IJInventorySlotNormalFirst <= item.slot && item.slot <= IJInventorySlotNormalLast)
		{
			[inventoryItem replaceObjectAtIndex:item.slot - IJInventorySlotNormalFirst withObject:item];
		}
		else if (IJInventorySlotArmorFirst <= item.slot && item.slot <= IJInventorySlotArmorLast)
		{
			[armorItem replaceObjectAtIndex:item.slot - IJInventorySlotArmorFirst withObject:item];
		}
	}
	
	[outlineView reloadData];
	[outlineView expandItem:nil expandChildren:YES];
	
	[inventoryView setItems:inventoryItem];
	[quickView setItems:quickItem];
	[armorView setItems:armorItem];
	
	dirty = NO;
	statusTextField.stringValue = @"";
}

- (void)saveToWorldAtIndex:(int)worldIndex
{
	if (![IJMinecraftLevel checkSessionLockAtIndex:worldIndex value:sessionLockValue])
	{
		NSBeginCriticalAlertSheet(@"Another application has modified this world.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, @"The session lock was changed by another application.");
		return;
	}
	
	NSString *levelPath = [IJMinecraftLevel pathForLevelDatAtIndex:worldIndex];
	
	NSMutableArray *newInventory = [NSMutableArray array];
	
	for (NSArray *items in rootItems)
	{
		for (IJInventoryItem *item in items)
		{
			if (item.count > 0 && item.itemId > 0)
				[newInventory addObject:item];
		}
	}
	
	[level setInventory:newInventory];
	
	NSString *backupPath = [levelPath stringByAppendingPathExtension:@"insidejobbackup"];
	
	BOOL success;
	NSError *error = nil;
	success = [[NSFileManager defaultManager] removeItemAtPath:backupPath error:&error];
	success = [[NSFileManager defaultManager] copyItemAtPath:levelPath
													  toPath:backupPath
													   error:&error];
	if (!success)
	{
		NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, @"Inside Job was unable to create a backup of the existing level file.");
		return;
	}
	
	[[level writeData] writeToURL:[NSURL fileURLWithPath:levelPath] atomically:NO];
	
	dirty = NO;
	statusTextField.stringValue = @"Saved.";
}

- (void)markDirty
{
	dirty = YES;
	statusTextField.stringValue = @"World has unsaved changes.";
}

#pragma mark -
#pragma mark Actions

- (IBAction)worldSelectionChanged:(id)sender
{
	int worldIndex = [worldSelectionControl selectedSegment] + 1;
	[self loadWorldAtIndex:worldIndex];
}

- (void)saveDocument:(id)sender
{
	int worldIndex = [worldSelectionControl selectedSegment] + 1;
	[self saveToWorldAtIndex:worldIndex];
}

- (void)delete:(id)sender
{
	IJInventoryItem *item = [outlineView itemAtRow:[outlineView selectedRow]];
	item.count = 0;
	item.itemId = 0;
	item.damage = 0;
	[self markDirty];
	[outlineView reloadItem:item];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if (anItem.action == @selector(delete:))
	{
		return [outlineView selectedRow] != -1 && ![rootItems containsObject:[outlineView itemAtRow:[outlineView selectedRow]]];
	}
	return YES;
}

- (NSNumber *)worldTime
{
	return 	[level worldTimeContainer].numberValue;
}
- (void)setWorldTime:(NSNumber *)number
{
	[self willChangeValueForKey:@"worldTime"];
	[level worldTimeContainer].numberValue = number;
	[self didChangeValueForKey:@"worldTime"];
	[self markDirty];
}

#pragma mark -
#pragma mark IJInventoryViewDelegate

- (NSMutableArray *)itemArrayForInventoryView:(IJInventoryView *)theInventoryView slotOffset:(int*)slotOffset
{
	if (theInventoryView == inventoryView)
	{
		*slotOffset = IJInventorySlotNormalFirst;
		return inventoryItem;
	}
	else if (theInventoryView == quickView)
	{
		*slotOffset = IJInventorySlotQuickFirst;
		return quickItem;
	}
	else if (theInventoryView == armorView)
	{
		*slotOffset = IJInventorySlotArmorFirst;
		return armorItem;
	}
	return nil;
}

- (void)inventoryView:(IJInventoryView *)theInventoryView removeItemAtIndex:(int)itemIndex
{
	int slotOffset = 0;
	NSMutableArray *itemArray = [self itemArrayForInventoryView:theInventoryView slotOffset:&slotOffset];
	
	if (itemArray)
	{
		IJInventoryItem *item = [IJInventoryItem emptyItemWithSlot:slotOffset + itemIndex];
		[itemArray replaceObjectAtIndex:itemIndex withObject:item];
		[theInventoryView setItems:itemArray];
	}
	[self markDirty];
}

- (void)inventoryView:(IJInventoryView *)theInventoryView setItem:(IJInventoryItem *)item atIndex:(int)itemIndex
{
	int slotOffset = 0;
	NSMutableArray *itemArray = [self itemArrayForInventoryView:theInventoryView slotOffset:&slotOffset];
	
	if (itemArray)
	{
		[itemArray replaceObjectAtIndex:itemIndex withObject:item];
		item.slot = slotOffset + itemIndex;
		[theInventoryView setItems:itemArray];
	}
	[self markDirty];
}

#pragma mark -
#pragma mark Item Picker



@end
