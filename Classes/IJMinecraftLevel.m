//
//  IJMinecraftLevel.m
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJMinecraftLevel.h"
#import "IJInventoryItem.h"

@implementation IJMinecraftLevel

- (NBTContainer *)containerWithName:(NSString *)theName inArray:(NSArray *)array
{
	for (NBTContainer *container in array)
	{
		if ([container.name isEqual:theName])
			return container;
	}
	return nil;
}

- (NBTContainer *)inventoryList
{
	// Inventory is found in:
	// - compound "Data"
	//   - compound "Player"
	//     - list "Inventory"
	//       *
	NBTContainer *dataCompound = [self childNamed:@"Data"];
	NBTContainer *playerCompound = [dataCompound childNamed:@"Player"];
	NBTContainer *inventoryList = [playerCompound childNamed:@"Inventory"];
	// TODO: Check for error conditions here.
	return inventoryList;
}

- (NSArray *)inventory
{
	NSMutableArray *output = [NSMutableArray array];
	for (NSArray *listItems in [self inventoryList].children)
	{
		IJInventoryItem *invItem = [[IJInventoryItem alloc] init];
		
		invItem.itemId = [[self containerWithName:@"id" inArray:listItems].numberValue shortValue];
		invItem.count = [[self containerWithName:@"Count" inArray:listItems].numberValue unsignedCharValue];
		invItem.damage = [[self containerWithName:@"Damage" inArray:listItems].numberValue shortValue];
		invItem.slot = [[self containerWithName:@"Slot" inArray:listItems].numberValue unsignedCharValue];
		[output addObject:invItem];
		[invItem release];
	}
	return output;
}

- (void)setInventory:(NSArray *)newInventory
{
	NSMutableArray *newChildren = [NSMutableArray array];
	NBTContainer *inventoryList = [self inventoryList];
	
	if (inventoryList.listType != NBTTypeCompound)
	{
		// There appears to be a bug in the way Minecraft writes empty inventory lists; it appears to
		// set the list type to 'byte', so we will correct it here.
		NSLog(@"%s Fixing inventory list type; was %d.", __PRETTY_FUNCTION__, inventoryList.listType);
		inventoryList.listType = NBTTypeCompound;
	}
	
	for (IJInventoryItem *invItem in newInventory)
	{
		NSArray *listItems = [NSArray arrayWithObjects:
							  [NBTContainer containerWithName:@"id" type:NBTTypeShort numberValue:[NSNumber numberWithShort:invItem.itemId]],
							  [NBTContainer containerWithName:@"Damage" type:NBTTypeShort numberValue:[NSNumber numberWithShort:invItem.damage]],
							  [NBTContainer containerWithName:@"Count" type:NBTTypeByte numberValue:[NSNumber numberWithShort:invItem.count]],
							  [NBTContainer containerWithName:@"Slot" type:NBTTypeByte numberValue:[NSNumber numberWithShort:invItem.slot]],
							  nil];
		[newChildren addObject:listItems];
	}
	inventoryList.children = newChildren;
}

- (NBTContainer *)worldTimeContainer
{
	return [[self childNamed:@"Data"] childNamed:@"Time"];
}

#pragma mark -
#pragma mark Helpers

+ (NSString *)pathForWorldAtIndex:(int)worldIndex
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *path = [paths objectAtIndex:0];
	path = [path stringByAppendingPathComponent:@"minecraft"];
	path = [path stringByAppendingPathComponent:@"saves"];
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"World%d", worldIndex]];
	return path;
}

+ (NSString *)pathForLevelDatAtIndex:(int)worldIndex
{
	return [[[self class] pathForWorldAtIndex:worldIndex] stringByAppendingPathComponent:@"level.dat"];
}
+ (NSString *)pathForSessionLockAtIndex:(int)worldIndex
{
	return [[[self class] pathForWorldAtIndex:worldIndex] stringByAppendingPathComponent:@"session.lock"];
}

+ (BOOL)worldExistsAtIndex:(int)worldIndex
{
	return [[NSFileManager defaultManager] fileExistsAtPath:[[self class] pathForLevelDatAtIndex:worldIndex]];
}

+ (NSData *)dataWithInt64:(int64_t)v
{
	NSMutableData *data = [NSMutableData data];
	uint32_t v0 = htonl(v >> 32);
	uint32_t v1 = htonl(v);
	[data appendBytes:&v0 length:4];
	[data appendBytes:&v1 length:4];
	return data;
}
+ (int64_t)int64FromData:(NSData *)data
{
	uint8_t *bytes = (uint8_t *)[data bytes];
	uint64_t n = ntohl(*((uint32_t *)(bytes + 0)));
	n <<= 32;
	n += ntohl(*((uint32_t *)(bytes + 4)));
	return n;
}

+ (int64_t)writeToSessionLockAtIndex:(int)worldIndex
{
	NSString *path = [IJMinecraftLevel pathForSessionLockAtIndex:worldIndex];
	NSDate *now = [NSDate date];
	NSTimeInterval interval = [now timeIntervalSince1970];
	int64_t milliseconds = (int64_t)(interval * 1000.0);
	// write as number of milliseconds
	
	NSData *data = [IJMinecraftLevel dataWithInt64:milliseconds];
	[data writeToFile:path atomically:YES];
	
	return milliseconds;
}

+ (BOOL)checkSessionLockAtIndex:(int)worldIndex value:(int64_t)checkValue
{
	NSString *path = [IJMinecraftLevel pathForSessionLockAtIndex:worldIndex];
	NSData *data = [NSData dataWithContentsOfFile:path];

	if (!data)
	{
		NSLog(@"Failed to read session lock at %@", path);
		return NO;
	}
	
	int64_t milliseconds = [IJMinecraftLevel int64FromData:data];
	return checkValue == milliseconds;
}


@end
