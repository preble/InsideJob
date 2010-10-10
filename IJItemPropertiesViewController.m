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

- (IBAction)closeButton:(id)sender
{
	[self.view.window.parentWindow makeKeyWindow];
	[self commitEditing];
	self.item = nil; // Hack to prevent this item as coming up as 'lastItem' if they click again.
}

@end
