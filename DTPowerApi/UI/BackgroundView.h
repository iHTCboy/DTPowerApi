//
//  BackgroundView.h
//  DTPowerApi
//
//  Created by leks on 13-5-15.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BackgroundView : NSView
{
    NSImage *_backgroundImage;
    NSColor *_backgroundColor;
}
@property (nonatomic, retain) NSImage *backgroundImage;
@property (nonatomic, retain) NSColor *backgroundColor;
@end
