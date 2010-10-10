//
//  InsideJobAppDelegate.h
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IJInventoryWindowController;

@interface InsideJobAppDelegate : NSObject <NSApplicationDelegate> {
    IJInventoryWindowController *inventoryWindowController;
}

@property (assign) IBOutlet IJInventoryWindowController *inventoryWindowController;

@end
