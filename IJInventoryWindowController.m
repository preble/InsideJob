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
#import "IJInventoryView.h"
#import "IJItemPropertiesViewController.h"
#import "MAAttachedWindow.h"

@interface IJInventoryWindowController ()
- (void)removePropertiesWindow;
@end

@implementation IJInventoryWindowController

@synthesize worldSelectionControl;
@synthesize statusTextField;
@synthesize inventoryView, armorView, quickView;
@synthesize itemSearchField, itemTableView;


- (void)awakeFromNib
{
	armorInventory = [[NSMutableArray alloc] init];
	quickInventory = [[NSMutableArray alloc] init];
	normalInventory = [[NSMutableArray alloc] init];
	statusTextField.stringValue = @"";
	
	[inventoryView setRows:3 columns:9 invert:NO];
	[quickView setRows:1 columns:9 invert:NO];
	[armorView setRows:4 columns:1 invert:YES];
	inventoryView.delegate = self;
	quickView.delegate = self;
	armorView.delegate = self;

	// Item Table View setup
	NSArray *keys = [[IJInventoryItem itemIdLookup] allKeys];
	keys = [keys sortedArrayUsingSelector:@selector(compare:)];
	allItemIds = [[NSArray alloc] initWithArray:keys];
	filteredItemIds = [allItemIds retain];
}

- (void)dealloc
{
	[propertiesViewController release];
	[armorInventory release];
	[quickInventory release];
	[normalInventory release];
	[inventory release];
	[level release];
	[super dealloc];
}


#pragma mark -
#pragma mark World Selection

- (void)loadWorldAtIndex:(int)worldIndex
{
	[armorInventory removeAllObjects];
	[quickInventory removeAllObjects];
	[normalInventory removeAllObjects];
	
	
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
		NSBeginCriticalAlertSheet(@"Error loading world.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, @"InsideJob was unable to load the level at %@.", levelPath);
		return;
	}
	
	[self willChangeValueForKey:@"worldTime"];
	
	level = [[IJMinecraftLevel nbtContainerWithData:fileData] retain];
	inventory = [[level inventory] retain];
	
	[self didChangeValueForKey:@"worldTime"];
	
	// Add placeholder inventory items:
	
	for (int i = 0; i < IJInventorySlotQuickLast + 1 - IJInventorySlotQuickFirst; i++)
		[quickInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotQuickFirst + i]];
	
	for (int i = 0; i < IJInventorySlotNormalLast + 1 - IJInventorySlotNormalFirst; i++)
		[normalInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotNormalFirst + i]];
	
	for (int i = 0; i < IJInventorySlotArmorLast + 1 - IJInventorySlotArmorFirst; i++)
		[armorInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotArmorFirst + i]];
	
	
	// Overwrite the placeholders with actual inventory:
	
	for (IJInventoryItem *item in inventory)
	{
		if (IJInventorySlotQuickFirst <= item.slot && item.slot <= IJInventorySlotQuickLast)
		{
			[quickInventory replaceObjectAtIndex:item.slot - IJInventorySlotQuickFirst withObject:item];
		}
		else if (IJInventorySlotNormalFirst <= item.slot && item.slot <= IJInventorySlotNormalLast)
		{
			[normalInventory replaceObjectAtIndex:item.slot - IJInventorySlotNormalFirst withObject:item];
		}
		else if (IJInventorySlotArmorFirst <= item.slot && item.slot <= IJInventorySlotArmorLast)
		{
			[armorInventory replaceObjectAtIndex:item.slot - IJInventorySlotArmorFirst withObject:item];
		}
	}
	
	NSLog(@"normal: %@", normalInventory);
	NSLog(@"quick: %@", quickInventory);
	
	[inventoryView setItems:normalInventory];
	[quickView setItems:quickInventory];
	[armorView setItems:armorInventory];
	
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
	
	for (NSArray *items in [NSArray arrayWithObjects:armorInventory, quickInventory, normalInventory, nil])
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
//	IJInventoryItem *item = [outlineView itemAtRow:[outlineView selectedRow]];
//	item.count = 0;
//	item.itemId = 0;
//	item.damage = 0;
//	[self markDirty];
//	[outlineView reloadItem:item];
}

- (IBAction)makeSearchFieldFirstResponder:(id)sender
{
	[itemSearchField becomeFirstResponder];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
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
		if (slotOffset) *slotOffset = IJInventorySlotNormalFirst;
		return normalInventory;
	}
	else if (theInventoryView == quickView)
	{
		if (slotOffset) *slotOffset = IJInventorySlotQuickFirst;
		return quickInventory;
	}
	else if (theInventoryView == armorView)
	{
		if (slotOffset) *slotOffset = IJInventorySlotArmorFirst;
		return armorInventory;
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

- (void)inventoryView:(IJInventoryView *)theInventoryView selectedItemAtIndex:(int)itemIndex
{
	NSLog(@"%s index=%d", _cmd, itemIndex);
	// Show the properties window for this item.
	IJInventoryItem *lastItem = propertiesViewController.item;
	
	//[self removePropertiesWindow];
	
	NSPoint itemLocationInView = [theInventoryView pointForItemAtIndex:itemIndex];
	NSPoint point = [theInventoryView convertPoint:itemLocationInView toView:nil];
	point.x += 16 + 8;
	point.y -= 16;
	
	NSArray *items = [self itemArrayForInventoryView:theInventoryView slotOffset:nil];
	IJInventoryItem *item = [items objectAtIndex:itemIndex];
	if (item.itemId == 0 || lastItem == item)
	{
		propertiesViewController.item = nil;
		return; // can't show info on nothing
	}
	
	if (!propertiesViewController)
	{
		propertiesViewController = [[IJItemPropertiesViewController alloc] initWithNibName:@"ItemPropertiesView" bundle:nil];
		
		propertiesWindow = [[MAAttachedWindow alloc] initWithView:propertiesViewController.view
												  attachedToPoint:point
														 inWindow:self.window
														   onSide:MAPositionRight
													   atDistance:0];
		[propertiesWindow setBackgroundColor:[NSColor controlBackgroundColor]];
		[propertiesWindow setViewMargin:4.0];
		[propertiesWindow setAlphaValue:1.0];
		[[self window] addChildWindow:propertiesWindow ordered:NSWindowAbove];
	}
	if (observerObject)
		[[NSNotificationCenter defaultCenter] removeObserver:observerObject];
	observerObject = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResignKeyNotification
																	   object:propertiesWindow
																		queue:[NSOperationQueue mainQueue]
																   usingBlock:^(NSNotification *notification) {
																	   [propertiesViewController commitEditing];
																	   if (item.count == 0)
																		   item.itemId = 0;
																	   [theInventoryView reloadItemAtIndex:itemIndex];
																	   [propertiesWindow setAlphaValue:0.0];
																   }];
	propertiesViewController.item = item;
	[propertiesWindow setPoint:point side:MAPositionRight];
	[propertiesWindow makeKeyAndOrderFront:nil];
	[propertiesWindow setAlphaValue:1.0];
}

#pragma mark -
#pragma mark Item Picker


- (IBAction)updateItemSearchFilter:(id)sender
{
	NSString *filterString = [sender stringValue];
	
	if (filterString.length == 0)
	{
		[filteredItemIds autorelease];
		filteredItemIds = [allItemIds retain];
		[itemTableView reloadData];
		return;
	}
	
	NSMutableArray *results = [NSMutableArray array];
	
	for (NSNumber *itemId in allItemIds)
	{
		NSString *name = [[IJInventoryItem itemIdLookup] objectForKey:itemId];
		NSRange range = [name rangeOfString:filterString options:NSCaseInsensitiveSearch];
		if (range.location != NSNotFound)
		{
			[results addObject:itemId];
			continue;
		}
		
		// Also search the item id:
		range = [[itemId stringValue] rangeOfString:filterString];
		if (range.location != NSNotFound)
		{
			[results addObject:itemId];
			continue;
		}
	}
	
	[filteredItemIds autorelease];
	filteredItemIds = [results retain];
	[itemTableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView
{
	return filteredItemIds.count;
}
- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	// TODO: Change this, because the row will not correspond once we support sorting.
	NSNumber *itemId = [filteredItemIds objectAtIndex:row];
	
	if ([tableColumn.identifier isEqual:@"itemId"])
	{
		return itemId;
	}
	else if ([tableColumn.identifier isEqual:@"image"])
	{
		return [IJInventoryItem imageForItemId:[itemId shortValue]];
	}
	else
	{
		NSString *name = [[IJInventoryItem itemIdLookup] objectForKey:itemId];
		return name;
	}
}
- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:[NSArray arrayWithObjects:IJPasteboardTypeInventoryItem, nil] owner:nil];
	
	NSNumber *itemId = [filteredItemIds objectAtIndex:[rowIndexes firstIndex]];
	
	IJInventoryItem *item = [[IJInventoryItem alloc] init];
	item.itemId = [itemId shortValue];
	item.count = 1;
	item.damage = 0;
	item.slot = 0;
	
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:item]
			forType:IJPasteboardTypeInventoryItem];
	
	[item release];

	return YES;
}


#pragma mark -
#pragma mark 

- (void)reloadInventoryViewForItem:(IJInventoryItem *)item
{
	if ([normalInventory containsObject:item])
		[inventoryView reloadItemAtIndex:[normalInventory indexOfObject:item]];
	else if ([quickInventory containsObject:item])
		[quickView reloadItemAtIndex:[quickInventory indexOfObject:item]];
	else if ([armorInventory containsObject:item])
		[armorView reloadItemAtIndex:[armorInventory indexOfObject:item]];
}

- (void)removePropertiesWindow
{
	if (observerObject)
	{
		[propertiesViewController commitEditing];
		[[NSNotificationCenter defaultCenter] removeObserver:observerObject];
		observerObject = nil;
		
		[self reloadInventoryViewForItem:propertiesViewController.item];
		
		[self.window removeChildWindow:propertiesWindow];
		[propertiesWindow orderOut:nil];
		//[propertiesWindow release];
		propertiesWindow = nil;
		propertiesViewController.item = nil;
	}
}


@end
