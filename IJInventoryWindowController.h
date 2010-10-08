//
//  IJInventoryWindowController.h
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IJMinecraftLevel;

@interface IJInventoryWindowController : NSWindowController {
	IJMinecraftLevel *level;
	NSArray *inventory;
	
	NSOutlineView *outlineView;
	NSSegmentedControl *worldSelectionControl;
	NSTextField *statusTextField;
	
	NSArray *rootItems;
	NSMutableArray *armorItem;
	NSMutableArray *quickItem;
	NSMutableArray *inventoryItem;
	
	BOOL dirty;
	int64_t sessionLockValue;
}

@property (nonatomic, assign) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *worldSelectionControl;
@property (nonatomic, assign) IBOutlet NSTextField *statusTextField;

@property (nonatomic, retain) NSNumber *worldTime;

- (IBAction)worldSelectionChanged:(id)sender;

@end
