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
	NSPopUpButton *worldPopup;
	NSTextField *statusTextField;
	
	NSArray *rootItems;
	NSMutableArray *armorItem;
	NSMutableArray *quickItem;
	NSMutableArray *inventoryItem;
	
	BOOL dirty;
	int64_t sessionLockValue;
}

@property (nonatomic, assign) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, assign) IBOutlet NSPopUpButton *worldPopup;
@property (nonatomic, assign) IBOutlet NSTextField *statusTextField;

- (IBAction)worldSelectionChanged:(id)sender;

@end
