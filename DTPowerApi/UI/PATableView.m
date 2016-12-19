//
//  PATableView.m
//  DTPowerApi
//
//  Created by leks on 13-5-15.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PATableView.h"
#import "CustomRowView.h"
#import "Global.h"

@implementation PATableView
@synthesize colors;

-(void)awakeFromNib
{
    self.colors = [NSArray arrayWithObjects:
                   [NSColor colorWithDeviceRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:1.0],
                   [NSColor colorWithDeviceRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0],
                   nil];
}


-(void)drawBackgroundInClipRect:(NSRect)clipRect
{
    // The super class implementation obviously does something more
    // than just drawing the striped background, because
    // if you leave this out it looks funny
    [super drawBackgroundInClipRect:clipRect];
    
    NSUInteger numberOfRows = self.numberOfRows;
    CGFloat yStart = 0;
    if (numberOfRows > 0) {
        yStart = NSMaxY([self rectOfRow:numberOfRows - 1]);
    }
    NSInteger rowIndex = numberOfRows + 1;
    
    while (yStart < NSMaxY(clipRect)+self.rowHeight)
    {
        CGFloat yRowTop = yStart - self.rowHeight;
        
        NSRect rowFrame = NSMakeRect(clipRect.origin.x, yRowTop, clipRect.size.width + 1000, self.rowHeight);
//        NSUInteger colorIndex = rowIndex % self.colors.count;
//        NSColor *color = [self.colors objectAtIndex:colorIndex];
//        [color set];
//        NSRectFill(rowFrame);
//        
//        CGContextRef currentContext = [[NSGraphicsContext currentContext]graphicsPort];
//        CGRect upline = rowFrame;
//        upline.origin.y -= 1;
//        upline.size.height = 1;
//        
//        [[NSColor colorWithDeviceRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0] set];
//        NSRectFill(upline);
//        upline.origin.y += 1;
//        [[NSColor whiteColor] set];
//        NSRectFill(upline);
        //        /* Slightly dark gray color */
        //        [[NSColor colorWithCalibratedWhite:0.0 alpha:1.000] set];
        //        /* Get the current graphics context */
        //
        //        /*Draw a one pixel line of the slightly lighter blue color */
        //        CGContextSetLineWidth(currentContext,1.0f);
        //        /* Start the line at the top of our cell*/
        //        CGContextMoveToPoint(currentContext,0.0f, yRowTop - self.rowHeight);
        //        /* End the line at the edge of our tableview, for multi-columns, this will actually be overkill*/
        //        CGContextAddLineToPoint(currentContext,NSMaxX(clipRect), yRowTop - self.rowHeight);
        //        /* Use the context's current color to draw the line */
        //        CGContextStrokePath(currentContext);
        //
        //        /* Slightly lighter blue color */
        //        [[NSColor colorWithCalibratedRed:0.961 green:0.970 blue:0.985 alpha:1.000] set];
        //        CGContextSetLineWidth(currentContext,1.0f);
        //        CGContextMoveToPoint(currentContext,0.0f,yRowTop);
        //        CGContextAddLineToPoint(currentContext,NSMaxX(self.bounds), yRowTop);
        //        CGContextStrokePath(currentContext);
        
        [gGlobalSetting.tableRowBgImage drawInRect:rowFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        
        rowFrame.origin.y = NSMaxY(rowFrame)-2;
        rowFrame.size.height = 2;
        
        [gGlobalSetting.tableGridHorizontalImage drawInRect:rowFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        
        yStart += self.rowHeight;
        rowIndex++;
    }
}
//
-(void)drawGridInClipRect:(NSRect)clipRect
{
//    [super drawGridInClipRect:clipRect];
    NSRect r = clipRect;
    r.size.width = 2;
    
    CGFloat x = 0;
    for (int i=0; i<self.tableColumns.count; i++)
    {
        NSTableColumn *column = [self.tableColumns objectAtIndex:i];
        x += column.width+2;
        r.origin.x = x+i;
        
//        [[self gridColor] set];
//        NSRectFill(r);
        [gGlobalSetting.tableGridVerticalImage drawInRect:r fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        r.origin.x += 1;
        
        //        [[NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:0.5] set];
        //        NSRectFill(r);
        
    }
    
    for (int j=0; j<self.numberOfRows; j++)
    {
        CustomRowView *row = [self rowViewAtRow:j makeIfNecessary:NO];
        //        [row drawSeparatorInRect:row.frame];
        [row setNeedsDisplay:YES];
    }
}


@end
