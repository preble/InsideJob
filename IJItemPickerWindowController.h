//
//  IJItemPickerWindowController.h
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IJItemPickerWindowController : NSWindowController {
	void(^completionBlock)(uint16_t itemId);
	NSTableView *tableView;
	NSArray *allItemIds;
	NSArray *filteredItemIds;
}
@property (nonatomic, assign) IBOutlet NSTableView *tableView;

+ (IJItemPickerWindowController *)sharedController;

- (void)showPickerWithInitialItemId:(uint16_t)initialItemId completionBlock:(void(^)(uint16_t itemId))block;

- (IBAction)itemActivated:(id)sender;
- (IBAction)updateFilter:(id)sender;

@end
