//
//  PAImage.h
//  DTPowerApi
//
//  Created by leks on 13-5-15.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct BFEdgeInsets {
    CGFloat top, left, bottom, right;
} BFEdgeInsets;

static inline BFEdgeInsets BFEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right) {
    BFEdgeInsets insets = {top, left, bottom, right};
    return insets;
}

@interface PAImage : NSImage
@property (assign) BFEdgeInsets stretchInsets;
-(void)sliceWidth:(CGFloat)width height:(CGFloat)height;
@end
