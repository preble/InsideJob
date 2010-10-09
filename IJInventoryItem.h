//
//  IJInventoryItem.h
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// See: http://www.minecraftwiki.net/wiki/Data_values
#define IJInventorySlotQuickFirst   (0)
#define IJInventorySlotQuickLast    (8)
#define IJInventorySlotNormalFirst  (9)
#define IJInventorySlotNormalLast  (35)
#define IJInventorySlotArmorLast  (103) // head
#define IJInventorySlotArmorFirst (100) // feet


@interface IJInventoryItem : NSObject {
	uint16_t itemId;
	uint16_t damage;
	uint8_t count;
	uint8_t slot;
}
@property (nonatomic, assign) uint16_t itemId;
@property (nonatomic, assign) uint16_t damage;
@property (nonatomic, assign) uint8_t count;
@property (nonatomic, assign) uint8_t slot;

@property (nonatomic, readonly) NSString *itemName;
@property (nonatomic, readonly) NSImage *image;

+ (id)emptyItemWithSlot:(uint8_t)slot;

+ (NSDictionary *)itemIdLookup;

@end
