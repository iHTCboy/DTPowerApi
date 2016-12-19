//
//  DMTableCellView.m
//  DTPowerApi
//
//  Created by leks on 13-6-27.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "DMTableCellView.h"

@implementation DMTableCellView
@synthesize normalColor;
@synthesize highlightedColor;

-(void)dealloc
{
    [normalColor release];
    [highlightedColor release];
    [super dealloc];
}
- (void)setBackgroundStyle:(NSBackgroundStyle)style
{
    [super setBackgroundStyle:style];
    
    
    // If the cell's text color is black, this sets it to white
    [((NSCell *)self.textField.cell) setBackgroundStyle:style];
    
    // Otherwise you need to change the color manually
    switch (style)
    {
        case NSBackgroundStyleLight:
        {
            self.textField.textColor = normalColor;
        }
            break;
            
        case NSBackgroundStyleDark:
        {
            self.textField.textColor = highlightedColor;
        }
            break;
        default:
            self.textField.textColor = normalColor;
            break;
    }
}
@end
