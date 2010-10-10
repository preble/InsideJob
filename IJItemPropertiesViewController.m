//
//  IJItemPropertiesViewController.m
//  InsideJob
//
//  Created by Adam Preble on 10/9/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJItemPropertiesViewController.h"
#import "IJInventoryItem.h"

@implementation IJItemPropertiesViewController

@synthesize item;

- (void)cancelOperation:(id)sender
{
	// Somewhat hacky method of closing the window on Esc.  Depends on us being the window's delegate.
	[self.view.window orderOut:nil];
}

@end
