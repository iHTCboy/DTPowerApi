//
//  ProjectTableRowView.m
//  DTPowerApi
//
//  Created by leks on 13-5-10.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "ProjectTableRowView.h"

@implementation ProjectTableRowView
@synthesize parentOutlineView;

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
    [super drawSelectionInRect:dirtyRect];
    [[NSColor colorWithCalibratedRed:110.0/255.0 green:115.0/255.0 blue:133.0/255.0 alpha:1.0] set];
    NSRectFill(dirtyRect);
}


-(NSBackgroundStyle)interiorBackgroundStyle
{
    if ([self isSelected])
    {
        return NSBackgroundStyleDark;
    }
    
    return NSBackgroundStyleLight;
}
@end
