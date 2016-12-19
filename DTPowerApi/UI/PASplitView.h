//
//  PASplitView.h
//  DTPowerApi
//
//  Created by leks on 13-5-29.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PASplitView : NSSplitView
{
    BOOL isSplitterAnimating;
}
- (void)setSplitterPosition:(float)newSplitterPosition animate:(BOOL)animate;
- (BOOL)isSplitterAnimating;
@end
