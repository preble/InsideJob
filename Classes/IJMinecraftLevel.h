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

+ (NSString *)pathForSessionLockForWorldAtURL:(NSURL *)worldURL;

+ (int64_t)writeToSessionLockForWorldAtURL:(NSURL *)worldURL;
+ (BOOL)checkSessionLockForWorldAtURL:(NSURL *)worldURL value:(int64_t)checkValue;


@end
