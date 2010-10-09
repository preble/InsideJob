//
//  IJItemMatrix.m
//  InsideJob
//
//  Created by Adam Preble on 10/8/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJItemMatrix.h"


@implementation IJItemMatrix

+ (id)itemMatrixWithFrame:(NSRect)frame rows:(int)rows columns:(int)cols
{
	NSMatrix *matrix = nil; // output
	NSImageCell *imageCellPrototype = [[[NSImageCell alloc] init] autorelease];
	[imageCellPrototype setImageFrameStyle:NSImageFrameGrayBezel];
	matrix = [[[self class] alloc] initWithFrame:frame
											mode:NSHighlightModeMatrix
									   prototype:imageCellPrototype
									numberOfRows:rows
								 numberOfColumns:cols];
	[matrix setCellSize:NSMakeSize(32+16, 32+16)];
	[matrix setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
	[matrix setDrawsBackground:NO];
	[matrix setDrawsCellBackground:NO];
	[matrix setIntercellSpacing:NSMakeSize(0, 0)];
	return [matrix autorelease];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
	{
        // Initialization code here.
    }
    return self;
}

- (void)dealloc
{
	[super dealloc];
}


@end
