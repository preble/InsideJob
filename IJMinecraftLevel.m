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

@end
