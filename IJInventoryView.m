//
//  IJInventoryView.m
//  InsideJob
//
//  Created by Adam Preble on 10/9/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJInventoryView.h"
#import "IJInventoryItem.h"
#import "MAAttachedWindow.h"
#import "NSColor+Additions.h"
#import <QuartzCore/QuartzCore.h>

NSString * const IJPasteboardTypeInventoryItem = @"net.adampreble.insidejob.inventoryitem";

const static CGFloat cellSize = 36;
const static CGFloat cellOffset = 40;

@implementation IJInventoryView

@synthesize delegate;

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
	{
        // Initialization code here.
		[self registerForDraggedTypes:[NSArray arrayWithObjects:IJPasteboardTypeInventoryItem, nil]];
    }
    return self;
}

- (void)dealloc
{
	[items release];
	[mouseDownEvent release];
	[super dealloc];
}

- (void)awakeFromNib
{
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (CGColorRef)borderColor
{
	return [[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] CGColor];
}
- (CGColorRef)highlightedBorderColor
{
	return [[NSColor colorWithCalibratedWhite:0 alpha:1.0] CGColor];
}

// For use by external stuff, since it flips the coordinates and our layer uses flipped geometry.
- (NSPoint)pointForItemAtIndex:(int)index
{
	int x = index % cols;
	int y = index / cols;
	return CGPointMake(x * cellOffset, self.bounds.size.height - y * cellOffset);
}

- (void)setRows:(int)numberOfRows columns:(int)numberOfColumns
{
	CALayer *layer = [CALayer layer];
	
	layer.bounds = NSRectToCGRect(self.bounds);
	layer.anchorPoint = CGPointZero;
	layer.position = CGPointZero; //CGPointMake(NSMidX(self.bounds), NSMidY(self.bounds));
	layer.geometryFlipped = YES;
	
	[self setLayer:layer];
	[self setWantsLayer:YES];
	

	rows = numberOfRows;
	cols = numberOfColumns;
	
	// reset the layers
	
	for (CALayer *layer in self.layer.sublayers)
	{
		[layer removeFromSuperlayer];
	}
	
	for (int y = 0; y < rows; y++)
	{
		for (int x = 0; x < cols; x++)
		{
			CALayer *layer = [CALayer layer];
			layer.anchorPoint = CGPointZero;
			layer.position = CGPointMake(x * cellOffset, y * cellOffset);
			layer.bounds = CGRectMake(0, 0, cellSize, cellSize);
			layer.borderWidth = 1.0;
			layer.borderColor = [self borderColor];
			layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.7 alpha:1.0] CGColor];
			layer.cornerRadius = 2.0;
			
			CALayer *imageLayer = [CALayer layer];
			imageLayer.position = CGPointMake(cellSize/2.0, cellSize/2.0);
			imageLayer.bounds = CGRectMake(0, 0, 32, 32);
			[layer addSublayer:imageLayer];
			
			CATextLayer *textLayer = [CATextLayer layer];
			textLayer.bounds = CGRectMake(0, 0, cellSize-2, 18);
			textLayer.position = CGPointMake(cellSize/2.0, cellSize/2.0 + 18/2 - 1);
			textLayer.foregroundColor = CGColorGetConstantColor(kCGColorWhite);
			textLayer.fontSize = 18;
			textLayer.shadowOpacity = 1.0;
			textLayer.shadowRadius = 0.5;
			textLayer.shadowOffset = NSMakeSize(0, 1);
			textLayer.alignmentMode = @"right";
			[layer addSublayer:textLayer];
			
			[self.layer addSublayer:layer];
		}
	}
}

- (CALayer *)layerAtRow:(int)row column:(int)column
{
	return [self.layer.sublayers objectAtIndex:row * cols + column];
}

- (void)reloadItemAtIndex:(int)itemIndex
{
	IJInventoryItem *item = [items objectAtIndex:itemIndex];
	CALayer *layer = [self.layer.sublayers objectAtIndex:itemIndex];
	
	CALayer *imageLayer = [layer.sublayers objectAtIndex:0];
	imageLayer.contents = item.image;
	
	CATextLayer *textLayer = [layer.sublayers objectAtIndex:1];
	if (item.count == 0)
		textLayer.string = @"";
	else
		textLayer.string = [NSString stringWithFormat:@"%d", item.count];
}

- (void)setItems:(NSArray *)theItems
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	[items autorelease];
	[theItems retain];
	items = theItems;
	
	for (int i = 0; i < items.count; i++)
		[self reloadItemAtIndex:i];
}

- (int)itemIndexForPoint:(NSPoint)point
{
	point.y = self.bounds.size.height - point.y;
	point.x /= cellOffset;
	point.y /= cellOffset;
	int index = floor(point.y) * cols + floor(point.x); // flip y
	return index;
}

#pragma mark -
#pragma mark Drag & Drop: Source

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
//	NSLog(@"%s", __PRETTY_FUNCTION__);
//	if (propertiesWindow) // take the first mouse while the properties window is up.
//		return YES;
//	else
//		return NO;
	// the above doesn't work since the window has already been dismissed by the time we get here
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[theEvent retain];
	[mouseDownEvent release];
	mouseDownEvent = theEvent;
	dragging = NO;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint mouseDownPoint = [mouseDownEvent locationInWindow];
	NSPoint mouseDragPoint = [theEvent locationInWindow];
	float dragDistance = hypot(mouseDownPoint.x - mouseDragPoint.x, mouseDownPoint.y - mouseDragPoint.y);
	if (dragDistance < 3)
		return;
	
	dragging = YES;
	
	// Find the IJInventoryItem:
	NSPoint pointInView = [self convertPoint:mouseDownPoint fromView:nil];
	int itemIndex = [self itemIndexForPoint:pointInView];
	IJInventoryItem *item = [items objectAtIndex:itemIndex];
	if (item.itemId == 0)
		return; // can't drag nothing
	
	NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	
	[pasteboard declareTypes:[NSArray arrayWithObjects:IJPasteboardTypeInventoryItem, nil] owner:nil];
	
	[pasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:item]
				forType:IJPasteboardTypeInventoryItem];
	
	NSImage *image = item.image;
	
	// Now clear out item:
	[delegate inventoryView:self removeItemAtIndex:itemIndex];
	
	NSPoint dragPoint = NSMakePoint(pointInView.x - image.size.width*0.5, pointInView.y - image.size.height*0.5);
	
	[self dragImage:image
				 at:dragPoint
			 offset:NSZeroSize
			  event:mouseDownEvent
		 pasteboard:pasteboard
			 source:self
		  slideBack:NO];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (!dragging)
	{
		NSPoint mouseDownPoint = [mouseDownEvent locationInWindow];
		NSPoint pointInView = [self convertPoint:mouseDownPoint fromView:nil];
		
		int itemIndex = [self itemIndexForPoint:pointInView];
		[delegate inventoryView:self selectedItemAtIndex:itemIndex];
	}
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationEvery;
}
//- (void)draggedImage:(NSImage *)image beganAt:(NSPoint)screenPoint
//{
//	NSLog(@"%s", __PRETTY_FUNCTION__);
//}
- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	NSLog(@"%s operation=%d", __PRETTY_FUNCTION__, operation);
	
	if (operation == NSDragOperationMove)
	{
		// 
	}
}
//- (void)draggedImage:(NSImage *)image movedTo:(NSPoint)screenPoint
//{
//	NSLog(@"%s", __PRETTY_FUNCTION__);
//}


#pragma mark -
#pragma mark Drag & Drop: Destination

- (void)moveHighlightToLayerAtIndex:(int)index
{
	[self.layer.sublayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		CALayer *layer = obj;
		if (idx == index)
			layer.borderColor = [self highlightedBorderColor];
		else
			layer.borderColor = [self borderColor];
	}];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	// TODO: Detect and ignore same slot.
	int index = [self itemIndexForPoint:[self convertPoint:[sender draggingLocation] fromView:nil]];
	[self moveHighlightToLayerAtIndex:index];
	
	if ([[sender draggingSource] isKindOfClass:[self class]])
		return NSDragOperationMove; // moving between inventories
	else
		return NSDragOperationCopy; // copying from the item selector, presumably
}
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	// TODO: Detect and ignore same slot.
	int index = [self itemIndexForPoint:[self convertPoint:[sender draggingLocation] fromView:nil]];
	[self moveHighlightToLayerAtIndex:index];

	if ([[sender draggingSource] isKindOfClass:[self class]])
		return NSDragOperationMove; // moving between inventories
	else
		return NSDragOperationCopy; // copying from the item selector, presumably
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[self moveHighlightToLayerAtIndex:-1];
}
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSLog(@"%s operation=%d", __PRETTY_FUNCTION__, sender.draggingSourceOperationMask);
	
	int index = [self itemIndexForPoint:[self convertPoint:[sender draggingLocation] fromView:nil]];
	
	NSData *itemData = [[sender draggingPasteboard] dataForType:IJPasteboardTypeInventoryItem];
	IJInventoryItem *item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
	
	[delegate inventoryView:self setItem:item atIndex:index];
	return YES;
}
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	[self moveHighlightToLayerAtIndex:-1];
}


@end
