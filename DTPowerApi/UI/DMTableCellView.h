//
//  DMTableCellView.h
//  DTPowerApi
//
//  Created by leks on 13-6-27.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DMTableCellView : NSTableCellView
{
    NSColor *normalColor;
    NSColor *highlightedColor;
}
@property (nonatomic, retain) NSColor *normalColor;
@property (nonatomic, retain) NSColor *highlightedColor;
@end
