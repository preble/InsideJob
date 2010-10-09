//
//  IJInventoryView.m
//  InsideJob
//
//  Created by Adam Preble on 10/9/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJInventoryView.h"
#import "IJInventoryItem.h"
#import "IJItemPropertiesViewController.h"
#import "MAAttachedWindow.h"

NSString * const IJPasteboardTypeInventoryItem = @"net.adampreble.insidejob.inventoryitem";

const static CGFloat cellSize = 32;
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
	[propertiesViewController release];
	[super dealloc];
}

- (void)awakeFromNib
{
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}
- (void)removePropertiesWindow
{
	[self.window removeChildWindow:propertiesWindow];
	[propertiesWindow orderOut:nil];
	[propertiesWindow release];
	propertiesWindow = nil;
}
- (BOOL)resignFirstResponder
{
	[self removePropertiesWindow];
	return YES;
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
			layer.borderColor = CGColorGetConstantColor(kCGColorBlack);
			[self.layer addSublayer:layer];
		}
	}
}

- (CALayer *)layerAtRow:(int)row column:(int)column
{
	return [self.layer.sublayers objectAtIndex:row * cols + column];
}

- (void)setItems:(NSArray *)theItems
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	[items autorelease];
	[theItems retain];
	items = theItems;
	
	//NSLog(@"%@ sublayers=%@", [self layer], self.layer.sublayers);
	[items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		IJInventoryItem *item = obj;
		CALayer *layer = [self.layer.sublayers objectAtIndex:idx];
		layer.contents = item.image;
	}];
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
		  slideBack:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (!dragging)
	{
		// Show the properties window for this item.
		
		[self removePropertiesWindow];
		
		NSPoint mouseDownPoint = [mouseDownEvent locationInWindow];
		NSPoint pointInView = [self convertPoint:mouseDownPoint fromView:nil];
		
		int itemIndex = [self itemIndexForPoint:pointInView];
		IJInventoryItem *item = [items objectAtIndex:itemIndex];
		if (item.itemId == 0)
			return; // can't show info on nothing
		
		if (!propertiesViewController)
		{
			propertiesViewController = [[IJItemPropertiesViewController alloc] initWithNibName:@"ItemPropertiesView" bundle:nil];
		}
		propertiesViewController.item = item;
		propertiesWindow = [[MAAttachedWindow alloc] initWithView:propertiesViewController.view
												  attachedToPoint:mouseDownPoint
														 inWindow:self.window
														   onSide:MAPositionRight
													   atDistance:0];
		[propertiesWindow setViewMargin:10.0];
		[propertiesWindow setAlphaValue:0.0];
		[[propertiesWindow animator] setAlphaValue:1.0];
		[[self window] addChildWindow:propertiesWindow ordered:NSWindowAbove];
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
			layer.borderColor = CGColorGetConstantColor(kCGColorWhite);
		else
			layer.borderColor = CGColorGetConstantColor(kCGColorBlack);
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
