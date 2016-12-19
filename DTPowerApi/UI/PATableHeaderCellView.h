//
//  PATableHeaderView.h
//  DTPowerApi
//
//  Created by leks on 13-5-15.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PATableHeaderCellView : NSTableHeaderCell

- (void)drawWithFrame:(CGRect)cellFrame
          highlighted:(BOOL)isHighlighted
               inView:(NSView *)view;
@end
