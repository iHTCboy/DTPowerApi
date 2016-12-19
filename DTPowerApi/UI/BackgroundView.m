//
//  BackgroundView.m
//  DTPowerApi
//
//  Created by leks on 13-5-15.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "BackgroundView.h"

@implementation BackgroundView
@synthesize backgroundColor = _backgroundColor;
@synthesize backgroundImage = _backgroundImage;

-(void)dealloc
{
    [_backgroundImage release];
    [_backgroundColor release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    if (_backgroundColor)
    {
        [_backgroundColor set];
        NSRectFill(rect);
    }
    
//    if (_backgroundImage)
//    {
//        CGContextRef myContext = [[NSGraphicsContext // 1
//                                   currentContext] graphicsPort];
//        NSRect r ;
//        CGImageRef imgref = [_backgroundImage CGImageForProposedRect:&r context:&myContext hints:nil];
//        CGContextDrawTiledImage(myContext, CGRectMake(0, 0, _backgroundImage.size.width, _backgroundImage.size.height), imgref);
//        
////        [_backgroundImage drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//        
//        
//    }
    
}
@end
