//
//  NSColor+Additions.m
//  InsideJob
//
//  Created by Adam Preble on 10/10/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "NSColor+Additions.h"


@implementation NSColor (Additions)

- (CGColorRef)CGColor
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSColor *deviceColor = [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	CGFloat components[4];
	[deviceColor getRed: &components[0] green: &components[1] blue:&components[2] alpha: &components[3]];
	
	CGColorRef output = CGColorCreate(colorSpace, components);
	CGColorSpaceRelease (colorSpace);
	return (CGColorRef)[(id)output autorelease];
}

@end
