//
//  ProjectTableRowView.h
//  DTPowerApi
//
//  Created by leks on 13-5-10.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProjectTableRowView : NSTableRowView
{
    NSOutlineView *parentOutlineView;
}
@property (nonatomic, assign) NSOutlineView *parentOutlineView;
@end
