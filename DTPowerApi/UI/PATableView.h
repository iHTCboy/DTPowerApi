//
//  PATableView.h
//  DTPowerApi
//
//  Created by leks on 13-5-15.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PATableView : NSTableView
{
    NSArray *colors;
}
@property (nonatomic, retain) NSArray *colors;
@end
