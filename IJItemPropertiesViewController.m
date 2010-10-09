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

+ (NSSet *)keyPathsForValuesAffectingCountNumber
{
	return [NSSet setWithObject:@"item"];
}
+ (NSSet *)keyPathsForValuesAffectingDamageNumber
{
	return [NSSet setWithObject:@"item"];
}

- (NSNumber *)countNumber
{
	return [NSNumber numberWithShort:item.count];
}
- (void)setCountNumber:(NSNumber *)number
{
	item.count = [number shortValue];
}

- (NSNumber *)damageNumber
{
	return [NSNumber numberWithShort:item.damage];
}
- (void)setDamageNumber:(NSNumber *)number
{
	item.damage = [number shortValue];
}

@end
