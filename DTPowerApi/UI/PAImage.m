//
//  PAImage.m
//  DTPowerApi
//
//  Created by leks on 13-5-15.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAImage.h"

@interface PAImage ()
{
    NSMutableDictionary *_slices;
}
@property (nonatomic, retain) NSMutableDictionary *slices;
@end

@implementation PAImage
@synthesize slices = _slices;

-(void)dealloc
{
    [_slices release];
    [super dealloc];
}

//-(void)drawInRect:(NSRect)rect fromRect:(NSRect)fromRect operation:(NSCompositingOperation)op fraction:(CGFloat)delta
//{
//    NSImage *topLeft = [self.slices objectForKey:@"topLeft"];
//    NSImage *topRight = [self.slices objectForKey:@"topRight"];
//    NSImage *bottomLeft = [self.slices objectForKey:@"bottomLeft"];
//    NSImage *bottomRight = [self.slices objectForKey:@"bottomRight"];
//    
//    CGFloat leftCapWidth = self.stretchInsets.left;
//    CGFloat topCapHeight = self.stretchInsets.top;
//    CGFloat rightCapWidth = self.stretchInsets.right;
//    CGFloat bottomCapHeight = self.stretchInsets.bottom;
//    
//    [topLeft drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
//    [topLeft drawAtPoint:NSMakePoint(0, bottomCapHeight) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
//    [topRight drawAtPoint:NSMakePoint(leftCapWidth, bottomCapHeight) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
//    [bottomLeft drawAtPoint:NSMakePoint(0, bottomCapHeight) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
//    [bottomRight drawAtPoint:NSMakePoint(leftCapWidth, bottomCapHeight) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
//}

//-(void)drawInRect:(NSRect)rect fromRect:(NSRect)fromRect operation:(NSCompositingOperation)op fraction:(CGFloat)delta
//{
//    int a = 0;
//    if (!self.slices || [[self.slices allKeys] count] == 0)
//    {
//        [super drawInRect:rect fromRect:fromRect operation:op fraction:delta];
//        return ;
//    }
//    NSImage *topLeft = [self.slices objectForKey:@"topLeft"];
//     [topLeft drawInRect:NSMakeRect(30, 0, 16, 16) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//}

-(void)drawInRect:(NSRect)dstSpacePortionRect fromRect:(NSRect)srcSpacePortionRect operation:(NSCompositingOperation)op fraction:(CGFloat)requestedAlpha respectFlipped:(BOOL)respectContextIsFlipped hints:(NSDictionary *)hints
{
    if (!self.slices || [[self.slices allKeys] count] == 0)
    {
        [super drawInRect:dstSpacePortionRect fromRect:srcSpacePortionRect operation:op fraction:requestedAlpha respectFlipped:respectContextIsFlipped hints:hints];
        return ;
    }
    
//    [super drawInRect:dstSpacePortionRect fromRect:srcSpacePortionRect operation:op fraction:requestedAlpha respectFlipped:respectContextIsFlipped hints:hints];
    
    NSImage *topLeft = [self.slices objectForKey:@"topLeft"];
    NSImage *topEdge = [self.slices objectForKey:@"topEdge"];
    NSImage *topRight = [self.slices objectForKey:@"topRight"];
    
    NSImage *leftEdge = [self.slices objectForKey:@"leftEdge"];
    NSImage *center = [self.slices objectForKey:@"center"];
    NSImage *rightEdge = [self.slices objectForKey:@"rightEdge"];
    
    NSImage *bottomLeft = [self.slices objectForKey:@"bottomLeft"];
    NSImage *bottomEdge = [self.slices objectForKey:@"bottomEdge"];
    NSImage *bottomRight = [self.slices objectForKey:@"bottomRight"];
    
    CGFloat leftCapWidth = self.stretchInsets.left;
    CGFloat topCapHeight = self.stretchInsets.top;
    CGFloat rightCapWidth = self.stretchInsets.right;
    CGFloat bottomCapHeight = self.stretchInsets.bottom;
    
    //topleft topright
    [topLeft drawAtPoint:NSMakePoint(0, dstSpacePortionRect.size.height - topCapHeight) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
    [topRight drawAtPoint:NSMakePoint(dstSpacePortionRect.size.width - rightCapWidth, dstSpacePortionRect.size.height - topCapHeight) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
    
    //top edge
    NSRect r = NSMakeRect(leftCapWidth, dstSpacePortionRect.size.height - topCapHeight, dstSpacePortionRect.size.width - rightCapWidth - leftCapWidth, topEdge.size.height);
    if (r.size.width > 0 && r.size.height > 0) {
        [topEdge drawInRect:r fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    
    //left edge
    r = NSMakeRect(0, bottomCapHeight, leftEdge.size.width, dstSpacePortionRect.size.height-topCapHeight-bottomCapHeight);
    if (r.size.width > 0 && r.size.height > 0) {
        [leftEdge drawInRect:r fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    
    //right edge
    r = NSMakeRect(dstSpacePortionRect.size.width - rightCapWidth, bottomCapHeight, rightEdge.size.width, dstSpacePortionRect.size.height-topCapHeight-bottomCapHeight);
    if (r.size.width > 0 && r.size.height > 0) {
        [rightEdge drawInRect:r fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    
    //bottom edge
    r = NSMakeRect(leftCapWidth, 0, dstSpacePortionRect.size.width - leftCapWidth - rightCapWidth, bottomCapHeight);
    if (r.size.width > 0 && r.size.height > 0) {
        [bottomEdge drawInRect:r fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    
    //bottomleft, bottomright
    [bottomLeft drawAtPoint:NSMakePoint(0, 0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
    [bottomRight drawAtPoint:NSMakePoint(dstSpacePortionRect.size.width-self.stretchInsets.right, 0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
    
    //center
    r = NSMakeRect(leftCapWidth, bottomCapHeight, dstSpacePortionRect.size.width - leftCapWidth - rightCapWidth, dstSpacePortionRect.size.height-topCapHeight-bottomCapHeight);
    if (r.size.width > 0 && r.size.height > 0) {
        [center drawInRect:r fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
}

-(void)sliceWidth:(CGFloat)width height:(CGFloat)height
{
    self.slices = [NSMutableDictionary dictionaryWithCapacity:10];
    
    CGFloat leftCapWidth = width;
    CGFloat topCapHeight = height;
    CGFloat rightCapWidth = self.size.width - width;
    CGFloat bottomCapHeight = self.size.height - height;
    
    self.stretchInsets = BFEdgeInsetsMake(topCapHeight, leftCapWidth, bottomCapHeight, rightCapWidth);
    
    CGSize centerSize = CGSizeMake(1, 1);
    
    NSImage *topLeft = [self sliceFromRect:NSMakeRect(0.0f, self.size.height - topCapHeight, leftCapWidth, topCapHeight)];
    
    NSImage *topEdge = [self sliceFromRect:NSMakeRect(leftCapWidth, self.size.height - topCapHeight, 1, topCapHeight)];
    
    NSImage *topRight = [self sliceFromRect:NSMakeRect(self.size.width - rightCapWidth, self.size.height - topCapHeight, rightCapWidth, topCapHeight)];
    
    NSImage *leftEdge = [self sliceFromRect:NSMakeRect(0.0f, bottomCapHeight, leftCapWidth, centerSize.height)];
    
    NSImage *center = [self sliceFromRect:NSMakeRect(leftCapWidth, topCapHeight, centerSize.width, centerSize.height)];
    
    NSImage *rightEdge = [self sliceFromRect:NSMakeRect(self.size.width - rightCapWidth, bottomCapHeight, rightCapWidth, centerSize.height)];
    
    NSImage *bottomLeft = [self sliceFromRect:NSMakeRect(0.0f, 0.0f, leftCapWidth, bottomCapHeight)];
    
    NSImage *bottomEdge = [self sliceFromRect:NSMakeRect(leftCapWidth, 0.0f, centerSize.width, bottomCapHeight)];
    NSImage *bottomRight = [self sliceFromRect:NSMakeRect(self.size.width - rightCapWidth, 0.0f, rightCapWidth, bottomCapHeight)];
    
    [self.slices setObject:topLeft forKey:@"topLeft"];
    [self.slices setObject:topEdge forKey:@"topEdge"];
    [self.slices setObject:topRight forKey:@"topRight"];
    
    [self.slices setObject:leftEdge forKey:@"leftEdge"];
    [self.slices setObject:center forKey:@"center"];
    [self.slices setObject:rightEdge forKey:@"rightEdge"];
    
    [self.slices setObject:bottomLeft forKey:@"bottomLeft"];
    [self.slices setObject:bottomEdge forKey:@"bottomEdge"];
    [self.slices setObject:bottomRight forKey:@"bottomRight"];
}

- (NSImage *)sliceFromRect:(NSRect)rect  {
    NSImage *newImage = [[NSImage alloc] initWithSize:rect.size];
    if (newImage.isValid && rect.size.width > 0.0f && rect.size.height > 0.0f) {
        NSRect toRect = rect;
        toRect.origin = NSZeroPoint;
        [newImage lockFocus];
        [self drawInRect:toRect fromRect:rect operation:NSCompositeSourceOver fraction:1.0f];
        [newImage unlockFocus];
    }
#if ! __has_feature(objc_arc)
    return [newImage autorelease];
#else
    return newImage;
#endif
}
@end
