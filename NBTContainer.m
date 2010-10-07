//
//  NBTFile.m
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//
//  Spec for the Named Binary Tag format: http://www.minecraft.net/docs/NBT.txt

#import "NBTContainer.h"
#import "NSData+CocoaDevAdditions.h"


@interface NBTContainer ()
- (void)populateWithBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
- (uint8_t)byteFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
- (uint16_t)shortFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
- (uint32_t)intFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
- (uint64_t)longFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
- (NSString *)stringFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
@end


@implementation NBTContainer
@synthesize name, children, type;
@synthesize stringValue, numberValue;

- (id)init
{
	if ((self = [super init]))
	{
	}
	return self;
}
- (void)dealloc
{
	[name release];
	[children release];
	[stringValue release];
	[numberValue release];
	[super dealloc];
}


+ (id)nbtContainerWithData:(NSData *)data;
{
	id obj = [[[self class] alloc] init];
	[obj readFromData:data];
	return obj;
}

- (void)readFromData:(NSData *)data
{
	data = [data gzipInflate];
	
	const uint8_t *bytes = (const uint8_t *)[data bytes];
	
	uint32_t offset = 0;
	[self populateWithBytes:bytes offset:&offset];
}

- (void)populateWithBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	self.type = bytes[offset];
	offset += 1;
	
	self.name = [self stringFromBytes:bytes offset:&offset];
	
	if (self.type == NBTTypeCompound)
	{
		NSLog(@">> start compound named %@", self.name);
		self.children = [NSMutableArray array];
		
		while (1)
		{
			NBTType childType = bytes[offset];
			if (childType == NBTTypeEnd)
				break;
			
			NBTContainer *child = [[NBTContainer alloc] init];
			[child populateWithBytes:bytes offset:&offset];
			[self.children addObject:child];
			[child release];
		}
		NSLog(@"<< end compound %@", self.name);
	}
	else if (self.type == NBTTypeList)
	{
		NBTType listType = bytes[offset];
		offset += 1;
		uint32_t listLength = [self intFromBytes:bytes offset:&offset];
		
		NSLog(@">> start list named %@ with type=%d length=%d", self.name, listType, listLength);
		
		self.children = [NSMutableArray array];
		while (listLength > 0)
		{
			if (listType == NBTTypeDouble)
			{
				NSNumber *num = [NSNumber numberWithDouble:(double)[self longFromBytes:bytes offset:&offset]];
				[self.children addObject:num];
			}
			else
			{
				NSLog(@"Unhandled list type: %d", self.type);
			}
			listLength--;
		}
		
		NSLog(@"<< end list %@", self.name);
	}	
	else if (self.type == NBTTypeString)
	{
		self.stringValue = [self stringFromBytes:bytes offset:&offset];
		NSLog(@"   name=%@ stringValue=%@", self.name, self.stringValue);
	}
	else if (self.type == NBTTypeLong)
	{
		self.numberValue = [NSNumber numberWithUnsignedLongLong:[self longFromBytes:bytes offset:&offset]];
		NSLog(@"   name=%@ long value=%qu", self.name, [self.numberValue unsignedLongLongValue]);
	}
	else if (self.type == NBTTypeShort)
	{
		self.numberValue = [NSNumber numberWithUnsignedShort:[self shortFromBytes:bytes offset:&offset]];
		NSLog(@"   name=%@ short value=0x%x", self.name, [self.numberValue unsignedShortValue]);
	}
	else if (self.type == NBTTypeByte)
	{
		self.numberValue = [NSNumber numberWithUnsignedChar:[self byteFromBytes:bytes offset:&offset]];
		NSLog(@"   name=%@ byte value=0x%x", self.name, [self.numberValue unsignedCharValue]);
	}
	else
	{
		NSLog(@"Unhandled type: %d", self.type);
	}
	
	*offsetPointer = offset;
}

- (NSString *)stringFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	uint16_t length = (bytes[offset] << 8) | bytes[offset + 1];
	*offsetPointer += 2 + length;
	return [[[NSString alloc] initWithBytes:bytes + offset + 2 length:length encoding:NSUTF8StringEncoding] autorelease];
}
- (uint8_t)byteFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	uint8_t n = bytes[offset];
	*offsetPointer += 1;
	return n;
}
- (uint16_t)shortFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	uint16_t n = (bytes[offset + 0] << 8) | bytes[offset + 1];
	*offsetPointer += 2;
	return n;
}
- (uint32_t)intFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	uint32_t n = (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];
	*offsetPointer += 4;
	return n;
}
- (uint64_t)longFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	uint64_t n = (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];
	*offsetPointer += 4;
	n += (uint64_t)((bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3]) << 32;
	*offsetPointer += 4;
	return n;
}


- (NSData *)data
{
	NSMutableData *data = [NSMutableData data];
	uint8_t t = self.type;
	[data appendBytes:&t length:1];
	uint16_t nameLength = self.name.length;
	[data appendBytes:&nameLength length:2];
	[data appendBytes:[self.name UTF8String] length:self.name.length];
	
	return data;
}

@end
