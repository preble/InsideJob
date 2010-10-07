//
//  NBTFile.h
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	NBTTypeEnd = 0,
	NBTTypeByte = 1,
	NBTTypeShort = 2,
	NBTTypeInt = 3,
	NBTTypeLong = 4,
	NBTTypeFloat = 5,
	NBTTypeDouble = 6,
	NBTTypeByteArray = 7,
	NBTTypeString = 8,
	NBTTypeList = 9,
	NBTTypeCompound = 10,
} NBTType; 

@interface NBTContainer : NSObject {
	NSString *name;
	NSMutableArray *children;
	NBTType type;
	NSString *stringValue;
	NSNumber *numberValue;
	NBTType listType;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSMutableArray *children;
@property (nonatomic, assign) NBTType type;
@property (nonatomic, retain) NSString *stringValue;
@property (nonatomic, retain) NSNumber *numberValue;
@property (nonatomic, assign) NBTType listType;

+ (NBTContainer *)containerWithName:(NSString *)theName type:(NBTType)theType numberValue:(NSNumber *)theNumber;
+ (id)nbtContainerWithData:(NSData *)data;
- (void)readFromData:(NSData *)data;
- (NSData *)writeData;
- (NBTContainer *)childNamed:(NSString *)theName;
@end
