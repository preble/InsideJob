//
//  IJDocument.h
//  InsideJob
//
//  Created by Adam Preble on 3/26/11.
//  Copyright 2011 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IJInventoryView.h"

@class IJInventoryView;
@class IJMinecraftLevel;
@class MAAttachedWindow;
@class IJItemPropertiesViewController;


@interface IJDocument : NSDocument <IJInventoryViewDelegate> {
@private
	IJMinecraftLevel *level;
	NSArray *inventory;
	
	IBOutlet IJInventoryView *inventoryView;
	IBOutlet IJInventoryView *quickView;
	IBOutlet IJInventoryView *armorView;
	
	NSMutableArray *armorInventory;
	NSMutableArray *quickInventory;
	NSMutableArray *normalInventory;
	
	// Search/Item List
	IBOutlet NSSearchField *itemSearchField;
	IBOutlet NSTableView *itemTableView;
	NSArray *allItemIds;
	NSArray *filteredItemIds;
	
	// 
	IJItemPropertiesViewController *propertiesViewController;
	MAAttachedWindow *propertiesWindow;
	id observerObject;
	
	// Document
	int64_t sessionLockValue;
}

@property (nonatomic, retain) NSNumber *worldTime;

- (IBAction)updateItemSearchFilter:(id)sender;
- (IBAction)makeSearchFieldFirstResponder:(id)sender;
- (IBAction)itemTableViewDoubleClicked:(id)sender;


@end
