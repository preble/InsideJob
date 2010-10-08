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

@implementation IJInventoryWindowController

@synthesize outlineView;
@synthesize worldPopup;
@synthesize statusTextField;

- (void)awakeFromNib
{
	armorItem = [NSMutableArray array];
	quickItem = [NSMutableArray array];
	inventoryItem = [NSMutableArray array];
	rootItems = [[NSArray alloc] initWithObjects:armorItem, quickItem, inventoryItem, nil];
	statusTextField.stringValue = @"";
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
	
	[level release];
	level = [[IJMinecraftLevel nbtContainerWithData:fileData] retain];
	inventory = [[level inventory] retain];
	
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
	
	NSString *backupPath = [levelPath stringByAppendingPathExtension:@".insidejobbackup"];
	
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
	int worldIndex = [[worldPopup selectedItem] tag];
	[self loadWorldAtIndex:worldIndex];
}

- (void)saveDocument:(id)sender
{
	int worldIndex = [[worldPopup selectedItem] tag];
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

#pragma mark -
#pragma mark Inventory Outline View

- (id)outlineView:(NSOutlineView *)theOutlineView child:(NSInteger)index ofItem:(id)item
{
	if (item == nil)
	{
		return [rootItems objectAtIndex:index];
	}
	else
	{
		return [item objectAtIndex:index];
	}

}

- (BOOL)outlineView:(NSOutlineView *)theOutlineView isItemExpandable:(id)item
{
	return item == nil || [rootItems containsObject:item];
}

- (NSInteger)outlineView:(NSOutlineView *)theOutlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil)
	{
		return 3;
	}
	else if ([rootItems containsObject:item])
	{
		return [(NSArray *)item count];
	}
	else
	{
		return 0;
	}

}

- (id)outlineView:(NSOutlineView *)theOutlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if ([rootItems containsObject:item])
	{
		if ([tableColumn.identifier isEqual:@"slot"])
		{
			if (item == armorItem)
				return @"Armor";
			else if (item == quickItem)
				return @"Quick Inventory";
			else if (item == inventoryItem)
				return @"Inventory";
		}
		else
		{
			return nil;
		}
	}
	
	IJInventoryItem *invItem = item;
	
	if ([tableColumn.identifier isEqual:@"slot"])
	{
		return [NSString stringWithFormat:@"%d", invItem.slot];
	}
	else if ([tableColumn.identifier isEqual:@"id"])
	{
		if (invItem.itemId)
			return [NSNumber numberWithShort:invItem.itemId];
		else
			return nil;
	}
	else if ([tableColumn.identifier isEqual:@"item"])
	{
		if (invItem.itemId)
			return invItem.itemName;
		else
			return @"";
	}
	else if ([tableColumn.identifier isEqual:@"count"])
	{
		if (invItem.count)
			return [NSNumber numberWithUnsignedChar:invItem.count];
		else
			return nil;
	}
	else if ([tableColumn.identifier isEqual:@"damage"])
	{
		if (invItem.damage)
			return [NSNumber numberWithShort:invItem.damage];
		else
			return nil;
	}
	
	return nil;
}

- (void)outlineView:(NSOutlineView *)theOutlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	IJInventoryItem *invItem = item;
	if ([tableColumn.identifier isEqual:@"id"])
	{
		invItem.itemId = [object shortValue];
		[self markDirty];
	}
	else if ([tableColumn.identifier isEqual:@"count"])
	{
		invItem.count = [object unsignedCharValue];
		if (invItem.count > 64)
			invItem.count = 64;
		[self markDirty];
	}
	else if ([tableColumn.identifier isEqual:@"damage"])
	{
		invItem.damage = [object shortValue];
		[self markDirty];
	}
}

- (BOOL)outlineView:(NSOutlineView *)theOutlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([rootItems containsObject:item])
		return NO;
	else if ([tableColumn.identifier isEqual:@"item"])
	{
		IJInventoryItem *invItem = item;
		[[IJItemPickerWindowController sharedController] showPickerWithInitialItemId:invItem.itemId completionBlock:^(uint16_t itemId) {
			invItem.itemId = itemId;
			[outlineView reloadItem:item];
			[self markDirty];
		}];
		return NO;
	}
	else
	{
		return [tableColumn.identifier isEqual:@"slot"] == NO;
	}
}


@end
