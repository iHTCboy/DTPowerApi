//
//  PATableCellView.m
//  DTPowerApi
//
//  Created by leks on 13-5-15.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PATableCellView.h"

@implementation PATableCellView

- (void)setBackgroundStyle:(NSBackgroundStyle)style
{
    [super setBackgroundStyle:style];
    
    
    // If the cell's text color is black, this sets it to white
    [((NSCell *)self.textField.cell) setBackgroundStyle:style];
    
    // Otherwise you need to change the color manually
    self.textField.textColor = [NSColor colorWithDeviceRed:33.0/255.0 green:33.0/255.0 blue:33.0/255.0 alpha:1.0];
}
@end
