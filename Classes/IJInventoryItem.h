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


@interface IJInventoryItem : NSObject <NSCoding> {
	int16_t itemId;
	int16_t damage;
	int8_t count;
	int8_t slot;
}
@property (nonatomic, assign) int16_t itemId;
@property (nonatomic, assign) int16_t damage;
@property (nonatomic, assign) int8_t count;
@property (nonatomic, assign) int8_t slot;

@property (nonatomic, readonly) NSString *itemName;
@property (nonatomic, readonly) NSImage *image;

+ (id)emptyItemWithSlot:(uint8_t)slot;

+ (NSDictionary *)itemIdLookup;

+ (NSImage *)imageForItemId:(uint16_t)itemId;

@end
