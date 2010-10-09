//
//  IJInventoryView.h
//  InsideJob
//
//  Created by Adam Preble on 10/9/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IJInventoryView : NSView {
	int rows;
	int cols;
	
	NSEvent *mouseDownEvent;
	
	NSArray *items;
}

- (void)setRows:(int)numberOfRows columns:(int)numberOfColumns;
- (void)setItems:(NSArray *)theItems;

@end
