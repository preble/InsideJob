//
//  IJDocument.m
//  InsideJob
//
//  Created by Adam Preble on 3/26/11.
//  Copyright 2011 Adam Preble. All rights reserved.
//

#import "IJDocument.h"
#import "IJMinecraftLevel.h"
#import "IJInventoryItem.h"
#import "IJInventoryView.h"
#import "IJItemPropertiesViewController.h"
#import "MAAttachedWindow.h"

@interface IJDocument ()
@end

@implementation IJDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		armorInventory = [[NSMutableArray alloc] init];
		quickInventory = [[NSMutableArray alloc] init];
		normalInventory = [[NSMutableArray alloc] init];
		[self setHasUndoManager:NO];
    }
    
    return self;
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

- (NSString *)windowNibName
{
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
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
	
	[itemTableView setTarget:self];
	[itemTableView setDoubleAction:@selector(itemTableViewDoubleClicked:)];
	[itemTableView reloadData];
	
	
	[inventoryView setItems:normalInventory];
	[quickView setItems:quickInventory];
	[armorView setItems:armorInventory];
}

#pragma mark -
#pragma mark File Reading/Writing

// Save a "level~.dat" file as a backup.
- (BOOL)keepBackupFile
{
	return YES;
}

- (void)saveDocument:(id)sender
{
	if (![IJMinecraftLevel checkSessionLockForWorldAtURL:[self fileURL] value:sessionLockValue])
	{
		NSBeginCriticalAlertSheet(@"Another application has opened this world.", @"Dismiss", nil, nil, self.windowForSheet, nil, nil, nil, nil, @"The session lock was changed by another application. You must Revert this world in order to make changes.");
		return;
	}
	[super saveDocument:sender];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
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
	
	sessionLockValue = [IJMinecraftLevel writeToSessionLockForWorldAtURL:[self fileURL]];
	if (![IJMinecraftLevel checkSessionLockForWorldAtURL:[self fileURL] value:sessionLockValue])
	{
		NSBeginCriticalAlertSheet(@"Error loading world.", @"Dismiss", nil, nil, self.windowForSheet, nil, nil, nil, nil, @"Inside Job was unable obtain the session lock.");
		return NO;
	}
	
	NSData *fileData = [NSData dataWithContentsOfURL:absoluteURL];
	
	if (!fileData)
	{
		// Error loading 
		NSBeginCriticalAlertSheet(@"Error loading world.", @"Dismiss", nil, nil, self.windowForSheet, nil, nil, nil, nil, @"InsideJob was unable to load the level at %@.", [absoluteURL path]);
		return NO;
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
	
	//	NSLog(@"normal: %@", normalInventory);
	//	NSLog(@"quick: %@", quickInventory);
	
	// For the first time load these outlets will not be set (so we do it in windowControllerDidLoadNib:),
	// but in the case of a revert we need to do this.
	[inventoryView setItems:normalInventory];
	[quickView setItems:quickInventory];
	[armorView setItems:armorInventory];
	
	return YES;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	
//	if (![IJMinecraftLevel checkSessionLockForWorldAtURL:[self fileURL] value:sessionLockValue])
//	{
//		NSBeginCriticalAlertSheet(@"Another application has modified this world.", @"Dismiss", nil, nil, self.windowForSheet, nil, nil, nil, nil, @"The session lock was changed by another application.");
//		return NO;
//	}
	
	NSString *levelPath = [absoluteURL path];
	
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
	
	BOOL success = NO;
	NSError *error = nil;
	
//	// Remove a previously-created .insidejobbackup, if it exists:
//	if ([[NSFileManager defaultManager] fileExistsAtPath:backupPath])
//	{
//		success = [[NSFileManager defaultManager] removeItemAtPath:backupPath error:&error];
//		if (!success)
//		{
//			NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [error localizedDescription]);
//			NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.windowForSheet, nil, nil, nil, nil, @"Inside Job was unable to remove the prior backup of this level file:\n%@", [error localizedDescription]);
//			return NO;
//		}
//	}
//	
//	// Create the backup:
//	success = [[NSFileManager defaultManager] copyItemAtPath:levelPath toPath:backupPath error:&error];
//	if (!success)
//	{
//		NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [error localizedDescription]);
//		NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.windowForSheet, nil, nil, nil, nil, @"Inside Job was unable to create a backup of the existing level file:\n%@", [error localizedDescription]);
//		return NO;
//	}
	
	// Write the new level.dat out:
	success = [[level writeData] writeToURL:[NSURL fileURLWithPath:levelPath] options:0 error:&error];
	if (!success)
	{
		NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [error localizedDescription]);
		
		NSError *restoreError = nil;
		success = [[NSFileManager defaultManager] copyItemAtPath:backupPath toPath:levelPath error:&restoreError];
		if (!success)
		{
			NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [restoreError localizedDescription]);
			NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.windowForSheet, nil, nil, nil, nil, @"Inside Job was unable to save to the existing level file, and the backup could not be restored.\n%@\n%@", [error localizedDescription], [restoreError localizedDescription]);
		}
		else
		{
			NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.windowForSheet, nil, nil, nil, nil, @"Inside Job was unable to save to the existing level file, and the backup was successfully restored.\n%@", [error localizedDescription]);
		}
		return NO;
	}
	
	return YES;
}

- (void)setDocumentEdited
{
	[self updateChangeCount:NSChangeDone];
}

#pragma mark -
#pragma mark Actions


- (void)delete:(id)sender
{
	//	IJInventoryItem *item = [outlineView itemAtRow:[outlineView selectedRow]];
	//	item.count = 0;
	//	item.itemId = 0;
	//	item.damage = 0;
	//	[self setDocumentEdited];
	//	[outlineView reloadItem:item];
}

- (IBAction)makeSearchFieldFirstResponder:(id)sender
{
	[itemSearchField becomeFirstResponder];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if (anItem.action == @selector(saveDocument:))
		return inventory != nil;
	
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
	[self setDocumentEdited];
}

#pragma mark -
#pragma mark IJInventoryViewDelegate

- (IJInventoryView *)inventoryViewForItemArray:(NSMutableArray *)theItemArray
{
	if (theItemArray == normalInventory)
		return inventoryView;
	if (theItemArray == quickInventory)
		return quickView;
	if (theItemArray == armorInventory)
		return armorView;
	
	return nil;
}

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
	[self setDocumentEdited];
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
	[self setDocumentEdited];
}

- (void)inventoryView:(IJInventoryView *)theInventoryView selectedItemAtIndex:(int)itemIndex
{
	// Show the properties window for this item.
	IJInventoryItem *lastItem = propertiesViewController.item;
	
	NSPoint itemLocationInView = [theInventoryView pointForItemAtIndex:itemIndex];
	NSPoint point = [theInventoryView convertPoint:itemLocationInView toView:nil];
	point.x += 16 + 8;
	point.y -= 16;
	
	NSArray *items = [self itemArrayForInventoryView:theInventoryView slotOffset:nil];
	IJInventoryItem *item = [items objectAtIndex:itemIndex];
	//NSLog(@"%s index=%d item=%@", _cmd, itemIndex, item);
	if (item.itemId == 0 || lastItem == item)
	{
		// Perhaps caused by a bug, but it seems to be possible for the window to not be invisible at this point,
		// so we will set the alpha value here to be sure.
		[propertiesWindow setAlphaValue:0.0];
		propertiesViewController.item = nil;
		return; // can't show info on nothing
	}
	
	if (!propertiesViewController)
	{
		propertiesViewController = [[IJItemPropertiesViewController alloc] initWithNibName:@"ItemPropertiesView" bundle:nil];
		
		propertiesWindow = [[MAAttachedWindow alloc] initWithView:propertiesViewController.view
												  attachedToPoint:point
														 inWindow:theInventoryView.window
														   onSide:MAPositionRight
													   atDistance:0];
		[propertiesWindow setBackgroundColor:[NSColor controlBackgroundColor]];
		[propertiesWindow setViewMargin:4.0];
		[propertiesWindow setAlphaValue:1.0];
		[[theInventoryView window] addChildWindow:propertiesWindow ordered:NSWindowAbove];
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

- (NSMutableArray *)inventoryArrayWithEmptySlot:(NSUInteger *)slot
{
	for (NSMutableArray *inventoryArray in [NSArray arrayWithObjects:quickInventory, normalInventory, nil])
	{
		__block BOOL found = NO;
		[inventoryArray enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
			IJInventoryItem *item = obj;
			if (item.count == 0)
			{
				*slot = index;
				*stop = YES;
				found = YES;
			}
		}];
		if (found)
			return inventoryArray;
	}
	return nil;
}

- (IBAction)itemTableViewDoubleClicked:(id)sender
{
	NSUInteger slot;
	NSMutableArray *inventoryArray = [self inventoryArrayWithEmptySlot:&slot];
	if (!inventoryArray)
		return;
	
	IJInventoryItem *item = [inventoryArray objectAtIndex:slot];
	item.itemId = [[filteredItemIds objectAtIndex:[itemTableView selectedRow]] shortValue];
	item.count = 1;
	[self setDocumentEdited];
	
	IJInventoryView *invView = [self inventoryViewForItemArray:inventoryArray];
	[invView reloadItemAtIndex:slot];
	[self inventoryView:invView selectedItemAtIndex:slot];
}

#pragma mark -
#pragma mark NSWindowDelegate



#pragma mark -
#pragma mark NSControlTextEditingDelegate

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if (command == @selector(moveDown:))
	{
		if ([itemTableView numberOfRows] > 0)
		{
			[itemTableView.window makeFirstResponder:itemTableView];
			[itemTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		}
		return YES;
	}
	return YES;
}


@end
