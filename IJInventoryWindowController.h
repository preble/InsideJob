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

@interface IJInventoryWindowController : NSWindowController <NSCollectionViewDelegate, IJInventoryViewDelegate> {
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
	
	// Document
	BOOL dirty;
	int64_t sessionLockValue;
}

@property (nonatomic, assign) IBOutlet NSSegmentedControl *worldSelectionControl;
@property (nonatomic, assign) IBOutlet NSTextField *statusTextField;
@property (nonatomic, assign) IBOutlet IJInventoryView *inventoryView;
@property (nonatomic, assign) IBOutlet IJInventoryView *quickView;
@property (nonatomic, assign) IBOutlet IJInventoryView *armorView;

@property (nonatomic, retain) NSNumber *worldTime;

- (IBAction)worldSelectionChanged:(id)sender;

@end
