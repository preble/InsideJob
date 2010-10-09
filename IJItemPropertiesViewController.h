//
//  IJItemPropertiesViewController.h
//  InsideJob
//
//  Created by Adam Preble on 10/9/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IJInventoryItem;

@interface IJItemPropertiesViewController : NSViewController {
	IJInventoryItem *item;
}
@property (nonatomic, retain) IJInventoryItem *item;
@end
