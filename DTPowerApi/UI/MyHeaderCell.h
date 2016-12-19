//
//  MyHeaderCell.h
//  DTPowerApi
//
//  Created by leks on 13-3-26.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface MyHeaderCell : NSTableHeaderCell
{
}
- (void)drawWithFrame:(CGRect)cellFrame
          highlighted:(BOOL)isHighlighted
               inView:(NSView *)view;
@end