//
//  InsideJobAppDelegate.h
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InsideJobAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
