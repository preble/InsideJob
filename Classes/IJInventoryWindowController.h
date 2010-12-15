//
//  IJInventoryWindowController.h
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IJInventoryView.h"

@class IJInventoryView;
@class IJMinecraftLevel;
@class MAAttachedWindow;
@class IJItemPropertiesViewController;

@interface IJInventoryWindowController : NSWindowController <NSWindowDelegate, IJInventoryViewDelegate> {
	IJMinecraftLevel *level;
	NSArray *inventory;
	
	NSSegmentedControl *worldSelectionControl;
	NSTextField *statusTextField;
	
	IJInventoryView *inventoryView;
	IJInventoryView *quickView;
	IJInventoryView *armorView;
	
	NSMutableArray *armorInventory;
	NSMutableArray *quickInventory;
	NSMutableArray *normalInventory;
	
	// Search/Item List
	NSSearchField *itemSearchField;
	NSTableView *itemTableView;
	NSArray *allItemIds;
	NSArray *filteredItemIds;
	
	// 
	IJItemPropertiesViewController *propertiesViewController;
	MAAttachedWindow *propertiesWindow;
	id observerObject;
	
	// Document
	BOOL dirty;
	int64_t sessionLockValue;
	int loadedWorldIndex;
	int attemptedLoadWorldIndex;
}

@property (nonatomic, assign) IBOutlet NSSegmentedControl *worldSelectionControl;
@property (nonatomic, assign) IBOutlet NSTextField *statusTextField;
@property (nonatomic, assign) IBOutlet IJInventoryView *inventoryView;
@property (nonatomic, assign) IBOutlet IJInventoryView *quickView;
@property (nonatomic, assign) IBOutlet IJInventoryView *armorView;
@property (nonatomic, assign) IBOutlet NSSearchField *itemSearchField;
@property (nonatomic, assign) IBOutlet NSTableView *itemTableView;

@property (nonatomic, retain) NSNumber *worldTime;

- (IBAction)menuSelectWorld:(id)sender;
- (IBAction)worldSelectionChanged:(id)sender;
- (IBAction)updateItemSearchFilter:(id)sender;
- (IBAction)makeSearchFieldFirstResponder:(id)sender;
- (IBAction)itemTableViewDoubleClicked:(id)sender;

@end
