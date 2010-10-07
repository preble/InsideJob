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

@end
