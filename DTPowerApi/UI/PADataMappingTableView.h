//
//  PADataMappingTableView.h
//  DTPowerApi
//
//  Created by leks on 13-5-13.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PADataMappingTableView : NSOutlineView
{
    NSArray *colors;
}
@property (nonatomic, retain) NSArray *colors;
@end
