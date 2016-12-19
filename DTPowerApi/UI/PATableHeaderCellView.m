//
//  PATableHeaderView.m
//  DTPowerApi
//
//  Created by leks on 13-5-15.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PATableHeaderCellView.h"
#import "Global.h"

@implementation PATableHeaderCellView
- (void)drawWithFrame:(CGRect)cellFrame
          highlighted:(BOOL)isHighlighted
               inView:(NSView *)view
{
    CGRect fillRect, borderRect;
    CGRectDivide(cellFrame, &borderRect, &fillRect, 1.0, CGRectMaxYEdge);
    
    CGContextRef myContext = [[NSGraphicsContext // 1
                               currentContext] graphicsPort];
    NSRect r ;
    [gGlobalSetting.tableHeaderBgImage drawInRect:fillRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    NSRect grid_rect = cellFrame;
    grid_rect.size.height -= 3;
    grid_rect.origin.y += 1;
    grid_rect.origin.x = grid_rect.origin.x + grid_rect.size.width-1;
    grid_rect.size.width = 2;
    
    [gGlobalSetting.tableGridVerticalImage drawInRect:grid_rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    NSString *str = [self stringValue];
    if (str)
    {
        [str drawAtPoint:NSMakePoint(cellFrame.origin.x+10, 7) withAttributes:[NSDictionary dictionary]];
    }
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
