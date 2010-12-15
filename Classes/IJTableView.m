//
//  IJTableView.m
//  InsideJob
//
//  Created by Adam Preble on 12/14/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJTableView.h"


@implementation IJTableView

- (void)keyDown:(NSEvent *)theEvent
{
	unichar ch = [[theEvent characters] characterAtIndex:0];
	if (ch == '\r') // return key
	{
		[self sendAction:[self doubleAction] to:[self target]];
		return;
	}
	[super keyDown:theEvent];
}

@end
