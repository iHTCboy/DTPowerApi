//
//  BorderScrollView.h
//  DTPowerApi
//
//  Created by leks on 13-3-26.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BorderScrollView : NSScrollView
{
    NSColor *borderColor;
}
@property (nonatomic, retain) NSColor *borderColor;
@end
