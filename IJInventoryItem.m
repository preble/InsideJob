//
//  IJInventoryItem.m
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJInventoryItem.h"


@implementation IJInventoryItem

@synthesize itemId, slot, damage, count;

+ (id)emptyItemWithSlot:(uint8_t)slot
{
	IJInventoryItem *obj = [[[[self class] alloc] init] autorelease];
	obj.slot = slot;
	return obj;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init]))
	{
		itemId = [decoder decodeIntForKey:@"itemId"];
		slot = [decoder decodeIntForKey:@"slot"];
		damage = [decoder decodeIntForKey:@"damage"];
		count = [decoder decodeIntForKey:@"count"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:itemId forKey:@"itemId"];
	[coder encodeInt:slot forKey:@"slot"];
	[coder encodeInt:damage forKey:@"damage"];
	[coder encodeInt:count forKey:@"count"];
}


- (NSString *)itemName
{
	NSString *name = [[IJInventoryItem itemIdLookup] objectForKey:[NSNumber numberWithShort:self.itemId]];
	if (name)
		return name;
	else
		return [NSString stringWithFormat:@"%d", self.itemId];
}

- (NSImage *)image
{
	NSSize itemImageSize = NSMakeSize(32, 32);
	NSPoint atlasOffset;
	NSUInteger itemsPerRow = 9;
	NSUInteger pixelsPerColumn = 36;
	NSUInteger pixelsPerRow = 56;
	
	int index;
	
	if (self.itemId <= 85)
	{
		if (self.itemId <= 20)
			index = self.itemId - 1; // first item is 1
		else if (self.itemId == 35)
			index = self.itemId - (35 - 20);
		else if (self.itemId >= 37)
			index = self.itemId - (37 - 21);
		atlasOffset = NSMakePoint(36, 75);
	}
	else if (self.itemId >= 256 && self.itemId <= 346)
	{
		index = self.itemId - 256;
		atlasOffset = NSMakePoint(445, 23+52);
	}
	else if (self.itemId >= 2556 && self.itemId <= 2557)
	{
		index = self.itemId - 2556;
		atlasOffset = NSMakePoint(445+pixelsPerColumn, 23+52);
	}
	else
	{
		NSLog(@"%s error: unrecognized item id %d", __PRETTY_FUNCTION__, self.itemId);
		return nil;
	}

	atlasOffset.x += pixelsPerColumn * (index % itemsPerRow);
	atlasOffset.y += pixelsPerRow    * (index / itemsPerRow);
	
	NSRect atlasRect = NSMakeRect(atlasOffset.x, atlasOffset.y, itemImageSize.width, itemImageSize.height);
	

	NSImage *atlas = [NSImage imageNamed:@"DataValuesV110Transparent.png"];
	NSImage *output = [[NSImage alloc] initWithSize:itemImageSize];
	
	atlasRect.origin.y = atlas.size.height - atlasRect.origin.y;
	
	[NSGraphicsContext saveGraphicsState];
	
	[output lockFocus];
	
	[atlas drawInRect:NSMakeRect(0, 0, itemImageSize.width, itemImageSize.height)
			 fromRect:atlasRect
			operation:NSCompositeCopy
			 fraction:1.0];
	
	[output unlockFocus];
	
	[NSGraphicsContext restoreGraphicsState];
	
	return output;
}

+ (NSDictionary *)itemIdLookup
{
	static NSDictionary *lookup = nil;
	if (!lookup)
	{
		NSError *error = nil;
		NSString *lines = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Items" withExtension:@"csv"]
												   encoding:NSUTF8StringEncoding
													  error:&error];
		NSMutableDictionary *building = [NSMutableDictionary dictionary];
		[lines enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
			NSArray *components = [line componentsSeparatedByString:@","];
			NSNumber *itemId = [NSNumber numberWithShort:[[components objectAtIndex:0] intValue]];
			NSString *name = [components objectAtIndex:1];
			[building setObject:name forKey:itemId];
		}];
		lookup = [[NSDictionary alloc] initWithDictionary:building];
	}
	return lookup;
}

@end
