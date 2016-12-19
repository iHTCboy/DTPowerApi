//
//  CustomRowView.m
//  DTPowerApi
//
//  Created by leks on 13-3-26.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "CustomRowView.h"
#import "Global.h"

@implementation CustomRowView
@synthesize gridColor;
@synthesize parentOutlineView;
@synthesize rowIndex;

-(void)dealloc
{
    [gridColor release];
    [super dealloc];
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect
{
//    [super drawBackgroundInRect:dirtyRect];
    
    NSImage *bg = nil;
    if (rowIndex % 2 == 0) {
        bg = gGlobalSetting.datamappingTableRowBgImage1;
    }
    else
    {
        bg = gGlobalSetting.datamappingTableRowBgImage2;
    }
    
    NSRect rowFrame = dirtyRect;
    
    [bg drawInRect:dirtyRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    rowFrame.origin.y = NSMaxY(rowFrame)-1;
    rowFrame.size.height = 2;

    [gGlobalSetting.tableGridHorizontalImage drawInRect:rowFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)drawSeparatorInRect:(NSRect)dirtyRect
{
//    [super drawSeparatorInRect:dirtyRect];

    CGFloat x = 0;
    CGRect r = dirtyRect;
    r.size.width = 2;
    r.origin.y -= 1;

    for (int i=0; i<parentOutlineView.numberOfColumns; i++)
    {
        NSTableColumn *column = [parentOutlineView.tableColumns objectAtIndex:i];

        x += column.width+2;
        r.origin.x = x+i;
        
        [gGlobalSetting.tableGridVerticalImage drawInRect:r fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
}
//
//- (void)drawSelectionInRect:(NSRect)dirtyRect
//{
//    
//}
//
//- (void)drawSeparatorInRect:(NSRect)dirtyRect
//{
//    
//}
@end
