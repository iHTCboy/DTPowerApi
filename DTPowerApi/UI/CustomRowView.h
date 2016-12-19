//
//  CustomRowView.h
//  DTPowerApi
//
//  Created by leks on 13-3-26.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CustomRowView : NSTableRowView
{
    NSColor *gridColor;
    NSOutlineView *parentOutlineView;
    NSInteger rowIndex;
}
@property (nonatomic, retain) NSColor *gridColor;
@property (nonatomic, assign) NSOutlineView *parentOutlineView;
@property (nonatomic) NSInteger rowIndex;
@end
