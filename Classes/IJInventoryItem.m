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

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p itemId=%d name=%@ count=%d slot=%d damage=%d",
			NSStringFromClass([self class]), self, itemId, self.itemName, count, slot, damage];
}

- (NSString *)itemName
{
	NSString *name = [[IJInventoryItem itemIdLookup] objectForKey:[NSNumber numberWithShort:self.itemId]];
	if (name)
		return name;
	else
		return [NSString stringWithFormat:@"%d", self.itemId];
}

+ (NSImage *)imageForItemId:(uint16_t)itemId
{
	NSSize itemImageSize = NSMakeSize(32, 32);
	NSPoint atlasOffset;
	NSUInteger itemsPerRow = 9;
	NSUInteger pixelsPerColumn = 36;
	NSUInteger pixelsPerRow = 56;
	
	int index = 0;
	
	if (itemId <= 92)
	{
		if (itemId <= 25)
			index = itemId - 1; // first item is 1
		else if (itemId == 35)
			index = itemId - (35 - 25);
		else if (itemId >= 37)
			index = itemId - (37 - 26);
		atlasOffset = NSMakePoint(36, 75);
	}
	else if (itemId >= 256 && itemId <= 355)
	{
		index = itemId - 256;
		atlasOffset = NSMakePoint(445, 23+52);
	}
	else if (itemId == 2256)
	{
		index = 0;
		atlasOffset = NSMakePoint(445, pixelsPerRow*12+17);
	}
	else if (itemId == 2257)
	{
		index = 0;
		atlasOffset = NSMakePoint(445+pixelsPerColumn, pixelsPerRow*12+17);
	}
	else
	{
		NSLog(@"%s error: unrecognized item id %d", __PRETTY_FUNCTION__, itemId);
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
	
	return [output autorelease];
}

- (NSImage *)image
{
	return [IJInventoryItem imageForItemId:itemId];
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
			if ([line hasPrefix:@"#"]) // ignore lines with a # prefix
				return;
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
