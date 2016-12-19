//
//  PATableRowView.h
//  DTPowerApi
//
//  Created by leks on 13-5-15.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PATableRowView : NSTableRowView
{
    NSColor *gridColor;
    NSTableView *parentTableView;
}
@property (nonatomic, retain) NSColor *gridColor;
@property (nonatomic, assign) NSTableView *parentTableView;
@end
