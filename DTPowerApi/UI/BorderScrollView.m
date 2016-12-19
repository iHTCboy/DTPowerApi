//
//  BorderScrollView.m
//  DTPowerApi
//
//  Created by leks on 13-3-26.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "BorderScrollView.h"

@implementation BorderScrollView
@synthesize borderColor;

-(void)dealloc
{
    [borderColor release];
    [super dealloc];
}

-(void)awakeFromNib
{

}

- (void)drawRect:(NSRect)rect
{
//    [super drawRect:rect];
    [self drawBorder:rect];
    
}

-(void)drawBorder:(NSRect)rect{
    //  NSRect rect = [self bounds];
    NSRect frameRect = [self bounds];
    [[NSColor colorWithDeviceRed:205.0/255.0 green:205.0/255.0 blue:205.0/255.0 alpha:1.0] set];
    CGContextRef myContext = [[NSGraphicsContext // 1
                               currentContext] graphicsPort];
    CGContextStrokeRectWithWidth(myContext, frameRect, 2.0);
//    CGContextStrokeRect(myContext, frameRect);
    
//    if(rect.size.height < frameRect.size.height)
//        return;
//    NSRect newRect = NSMakeRect(rect.origin.x+2, rect.origin.y+2, rect.size.width-3, rect.size.height-3);
//    
//    NSBezierPath *textViewSurround = [NSBezierPath bezierPathWithRoundedRect:newRect xRadius:10 yRadius:10];
//    [textViewSurround setLineWidth:10.0f];
//    [[self borderColor] set];
//    [textViewSurround stroke];
}
@end
