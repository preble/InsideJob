//
//  IJMinecraftLevel.h
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NBTContainer.h"

@interface IJMinecraftLevel : NBTContainer {

}

@property (nonatomic, copy) NSArray *inventory; // Array of IJInventoryItem objects.
@property (nonatomic, readonly) NBTContainer *worldTimeContainer;

+ (NSString *)pathForWorldAtIndex:(int)worldIndex;
+ (NSString *)pathForLevelDatAtIndex:(int)worldIndex;
+ (NSString *)pathForSessionLockAtIndex:(int)worldIndex;

+ (int64_t)writeToSessionLockAtIndex:(int)worldIndex;
+ (BOOL)checkSessionLockAtIndex:(int)worldIndex value:(int64_t)checkValue;


@end
