//
//  IJInventoryView.h
//  InsideJob
//
//  Created by Adam Preble on 10/9/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IJInventoryViewDelegate;
@class IJInventoryItem;

@interface IJInventoryView : NSView {
	int rows;
	int cols;
	
	NSEvent *mouseDownEvent;
	
	NSArray *items;
	
	id<IJInventoryViewDelegate> delegate;
}
@property (nonatomic, assign) id<IJInventoryViewDelegate> delegate;

- (void)setRows:(int)numberOfRows columns:(int)numberOfColumns;
- (void)setItems:(NSArray *)theItems;

@end


@protocol IJInventoryViewDelegate <NSObject>
- (void)inventoryView:(IJInventoryView *)inventoryView removeItemAtIndex:(int)itemIndex;
- (void)inventoryView:(IJInventoryView *)inventoryView setItem:(IJInventoryItem *)item atIndex:(int)itemIndex;
@end
