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

- (void)appendString:(NSString *)str toData:(NSMutableData *)data;
- (void)appendByte:(uint8_t)v toData:(NSMutableData *)data;
- (void)appendShort:(uint16_t)v toData:(NSMutableData *)data;
- (void)appendInt:(uint32_t)v toData:(NSMutableData *)data;
- (void)appendLong:(uint64_t)v toData:(NSMutableData *)data;
- (void)appendFloat:(float)v toData:(NSMutableData *)data;
- (void)appendDouble:(double)v toData:(NSMutableData *)data;

- (NSData *)data;
@end


@implementation NBTContainer
@synthesize name, children, type;
@synthesize stringValue, numberValue, listType;

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

- (NSData *)writeData
{
	return [[self data] gzipDeflate];
}

- (void)populateWithBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	self.type = [self byteFromBytes:bytes offset:&offset];
	self.name = [self stringFromBytes:bytes offset:&offset];
	
	if (self.type == NBTTypeCompound)
	{
		NSLog(@">> start compound named %@", self.name);
		self.children = [NSMutableArray array];
		
		while (1)
		{
			NBTType childType = bytes[offset]; // peek
			if (childType == NBTTypeEnd)
			{
				offset += 1;
				break;
			}
			
			NBTContainer *child = [[NBTContainer alloc] init];
			[child populateWithBytes:bytes offset:&offset];
			[self.children addObject:child];
			[child release];
		}
		NSLog(@"<< end compound %@", self.name);
	}
	else if (self.type == NBTTypeList)
	{
		listType = [self byteFromBytes:bytes offset:&offset];
		uint32_t listLength = [self intFromBytes:bytes offset:&offset];
		
		NSLog(@">> start list named %@ with type=%d length=%d", self.name, listType, listLength);
		
		self.children = [NSMutableArray array];
		while (listLength > 0)
		{
			if (listType == NBTTypeFloat)
			{
				uint32_t i = [self intFromBytes:bytes offset:&offset];
				float f = *((float*)&i);
				NSNumber *num = [NSNumber numberWithFloat:f];
				[self.children addObject:num];
			}
			else if (listType == NBTTypeDouble)
			{
				uint64_t l = [self longFromBytes:bytes offset:&offset];
				double d = *((double*)&l);
				NSNumber *num = [NSNumber numberWithDouble:d];
				[self.children addObject:num];
			}
			else if (listType == NBTTypeCompound)
			{
				NSMutableArray *array = [NSMutableArray array];
				while (1)
				{
					NBTType childType = bytes[offset]; // peek
					if (childType == NBTTypeEnd)
					{
						offset += 1;
						break;
					}
					
					NBTContainer *child = [[NBTContainer alloc] init];
					[child populateWithBytes:bytes offset:&offset];
					[array addObject:child];
					[child release];
				}
				[self.children addObject:array];
			}
			else
			{
				NSLog(@"Unhandled list type: %d", listType);
			}
			listLength--;
		}
		
		NSLog(@"<< end list %@", self.name);
	}	
	else if (self.type == NBTTypeString)
	{
		self.stringValue = [self stringFromBytes:bytes offset:&offset];
		NSLog(@"   name=%@ string=%@", self.name, self.stringValue);
	}
	else if (self.type == NBTTypeLong)
	{
		self.numberValue = [NSNumber numberWithUnsignedLongLong:[self longFromBytes:bytes offset:&offset]];
		NSLog(@"   name=%@ long=%qu", self.name, [self.numberValue unsignedLongLongValue]);
	}
	else if (self.type == NBTTypeInt)
	{
		self.numberValue = [NSNumber numberWithUnsignedInt:[self intFromBytes:bytes offset:&offset]];
		NSLog(@"   name=%@ int=0x%x", self.name, [self.numberValue unsignedIntValue]);
	}
	else if (self.type == NBTTypeShort)
	{
		self.numberValue = [NSNumber numberWithUnsignedShort:[self shortFromBytes:bytes offset:&offset]];
		NSLog(@"   name=%@ short=0x%x", self.name, [self.numberValue unsignedShortValue]);
	}
	else if (self.type == NBTTypeByte)
	{
		self.numberValue = [NSNumber numberWithUnsignedChar:[self byteFromBytes:bytes offset:&offset]];
		NSLog(@"   name=%@ byte=0x%x", self.name, [self.numberValue unsignedCharValue]);
	}
	else if (self.type == NBTTypeFloat)
	{
		uint32_t i = [self intFromBytes:bytes offset:&offset];
		float f = *((float *)&i);
		self.numberValue = [NSNumber numberWithFloat:f];
		NSLog(@"   name=%@ float=%f", self.name, [self.numberValue floatValue]);
	}
	else
	{
		NSLog(@"Unhandled type: %d", self.type);
	}
	
	*offsetPointer = offset;
}


- (NSData *)data
{
	NSMutableData *data = [NSMutableData data];
	[self appendByte:self.type toData:data];
	[self appendString:self.name toData:data];
	
	if (self.type == NBTTypeCompound)
	{
		for (NBTContainer *child in self.children)
		{
			[data appendData:[child data]];
		}
		uint8_t t = NBTTypeEnd;
		[data appendBytes:&t length:1];
	}
	else if (self.type == NBTTypeList)
	{
		[self appendByte:self.listType toData:data];
		[self appendInt:self.children.count toData:data];
		for (id item in self.children)
		{
			if (listType == NBTTypeCompound)
			{
				for (NBTContainer *i in item)
				{
					[data appendData:[i data]];
				}
				uint8_t t = NBTTypeEnd;
				[data appendBytes:&t length:1];
			}
			else if (listType == NBTTypeFloat)
			{
				[self appendFloat:[item floatValue] toData:data];
			}
			else if (listType == NBTTypeDouble)
			{
				[self appendDouble:[item doubleValue] toData:data];
			}
			else
			{
				NSLog(@"Unhandled list type: %d", listType);
			}

		}
	}
	else if (self.type == NBTTypeString)
	{
		[self appendString:self.stringValue toData:data];
	}
	else if (self.type == NBTTypeLong)
	{
		[self appendLong:[self.numberValue unsignedLongLongValue] toData:data];
	}
	else if (self.type == NBTTypeShort)
	{
		[self appendShort:[self.numberValue unsignedShortValue] toData:data];
	}
	else if (self.type == NBTTypeInt)
	{
		[self appendInt:[self.numberValue unsignedIntValue] toData:data];
	}
	else if (self.type == NBTTypeByte)
	{
		[self appendByte:[self.numberValue unsignedCharValue] toData:data];
	}
	else if (self.type == NBTTypeDouble)
	{
		[self appendDouble:[self.numberValue doubleValue] toData:data];
	}
	else if (self.type == NBTTypeFloat)
	{
		[self appendFloat:[self.numberValue floatValue] toData:data];
	}
	else
	{
		NSLog(@"Unhandled type: %d", self.type);
	}

	
	return data;
}


#pragma mark -
#pragma mark Data Helpers


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
	uint32_t n = ntohl(*((uint32_t *)(bytes + offset)));
	*offsetPointer += 4;
	return n;
}
- (uint64_t)longFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	uint64_t n = ntohl(*((uint32_t *)(bytes + offset)));
	n <<= 32;
	offset += 4;
	n += ntohl(*((uint32_t *)(bytes + offset)));
	*offsetPointer += 8;
	return n;
}


- (void)appendString:(NSString *)str toData:(NSMutableData *)data
{
	[self appendShort:str.length toData:data];
	[data appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}
- (void)appendByte:(uint8_t)v toData:(NSMutableData *)data
{
	[data appendBytes:&v length:1];
}
- (void)appendShort:(uint16_t)v toData:(NSMutableData *)data
{
	v = htons(v);
	[data appendBytes:&v length:2];
}
- (void)appendInt:(uint32_t)v toData:(NSMutableData *)data
{
	v = htonl(v);
	[data appendBytes:&v length:4];
}
- (void)appendLong:(uint64_t)v toData:(NSMutableData *)data
{
	uint32_t v0 = htonl(v >> 32);
	uint32_t v1 = htonl(v);
	[data appendBytes:&v0 length:4];
	[data appendBytes:&v1 length:4];
}
- (void)appendFloat:(float)v toData:(NSMutableData *)data
{
	uint32_t vi = *((uint32_t *)&v);
	vi = htonl(vi);
	[data appendBytes:&vi length:4];
}
- (void)appendDouble:(double)v toData:(NSMutableData *)data
{
	uint64_t vl = *((uint64_t *)&v);
	uint32_t v0 = htonl(vl >> 32);
	uint32_t v1 = htonl(vl);
	[data appendBytes:&v0 length:4];
	[data appendBytes:&v1 length:4];
}


@end
