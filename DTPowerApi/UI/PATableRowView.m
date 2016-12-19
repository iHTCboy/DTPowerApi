//
//  PATableRowView.m
//  DTPowerApi
//
//  Created by leks on 13-5-15.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PATableRowView.h"
#import "Global.h"

@implementation PATableRowView
@synthesize gridColor;
@synthesize parentTableView;

-(void)dealloc
{
    [gridColor release];
    [super dealloc];
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect
{
//    [super drawBackgroundInRect:dirtyRect];
    [gGlobalSetting.tableRowBgImage drawInRect:dirtyRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    NSRect rowFrame = dirtyRect;
    
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
    
    for (int i=0; i<parentTableView.numberOfColumns; i++)
    {
        NSTableColumn *column = [parentTableView.tableColumns objectAtIndex:i];
        
        x += column.width+2;
        r.origin.x = x+i;
        
        [gGlobalSetting.tableGridVerticalImage drawInRect:r fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
}

-(void)drawSelectionInRect:(NSRect)dirtyRect
{
//    [super drawSelectionInRect:dirtyRect];
    
    [gGlobalSetting.tableRowHighlightedBgImage drawInRect:dirtyRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}
@end
