//
//  MyHeaderCell.m
//  DTPowerApi
//
//  Created by leks on 13-3-26.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "MyHeaderCell.h"
#import "Global.h"

@implementation MyHeaderCell

//-(id)initImageCell:(NSImage *)image
//{
//    return nil;
//}
//
//-(id)initTextCell:(NSString *)aString
//{
//    return nil;
//}
//
//-(id)initWithCoder:(NSCoder *)aDecoder
//{
//    return nil;
//}

- (void)drawWithFrame:(CGRect)cellFrame
          highlighted:(BOOL)isHighlighted
               inView:(NSView *)view
{
    CGRect fillRect, borderRect;
    CGRectDivide(cellFrame, &borderRect, &fillRect, 1.0, CGRectMaxYEdge);
//
//    NSGradient *gradient = [[NSGradient alloc]
//                            initWithStartingColor:[NSColor redColor]
//                            endingColor:[NSColor colorWithDeviceWhite:0.9 alpha:1.0]];
//    [gradient drawInRect:fillRect angle:90.0];
//    [gradient release];
//    
//    if (isHighlighted) {
//        [[NSColor colorWithDeviceWhite:0.0 alpha:0.1] set];
//        NSRectFillUsingOperation(fillRect, NSCompositeSourceOver);
//    }
//    
//    [[NSColor blackColor] set];
//    NSRectFill(borderRect);
    
    CGContextRef myContext = [[NSGraphicsContext // 1
                               currentContext] graphicsPort];
    
    [gGlobalSetting.tableHeaderBgImage drawInRect:fillRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    NSRect grid_rect = cellFrame;
    grid_rect.size.height -= 3;
    grid_rect.origin.y += 1;
    grid_rect.origin.x = grid_rect.origin.x + grid_rect.size.width-1;
    grid_rect.size.width = 2;
    
    [gGlobalSetting.tableGridVerticalImage drawInRect:grid_rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    CGContextSetRGBFillColor (myContext, 0, 0, 0, 1);
    NSString *str = [self stringValue];
    if (str)
    {
        [str drawAtPoint:NSMakePoint(cellFrame.origin.x+10, 7) withAttributes:[NSDictionary dictionary]];
    }
    
//    CGRect upline = fillRect;
//    upline.size.height = 1;
//    [[NSColor whiteColor] set];
//    CGContextFillRect(myContext, upline);
//    
//    CGRect leftline = cellFrame;
//    leftline.origin.x -= 1;
//    leftline.size.width = 1;
//    leftline.size.height = leftline.size.height + 1;
//    NSColor *leftColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1];
//    [leftColor set];
//    CGContextFillRect(myContext, leftline);
    
//    [self drawInteriorWithFrame:CGRectInset(fillRect, 0.0, 1.0) inView:view];
}
//
- (void)drawWithFrame:(CGRect)cellFrame inView:(NSView *)view
{
    [self drawWithFrame:cellFrame highlighted:NO inView:view];
}

- (void)highlight:(BOOL)isHighlighted
        withFrame:(NSRect)cellFrame
           inView:(NSView *)view
{
    [self drawWithFrame:cellFrame highlighted:isHighlighted inView:view];
}

@end