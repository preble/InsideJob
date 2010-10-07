//
//  IJInventoryItem.h
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>


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

@end
