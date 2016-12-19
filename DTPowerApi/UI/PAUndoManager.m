//
//  PAUndoManager.m
//  DTPowerApi
//
//  Created by leks on 13-5-27.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAUndoManager.h"
#import "Global.h"

@implementation PAUndoManager

-(void)beginUndoGrouping
{
    [super beginUndoGrouping];
    gNeedSave = YES;
    int a= 0;
}

-(void)endUndoGrouping
{
    [super endUndoGrouping];
    gNeedSave = YES;
    int a = 0;
    
}
- (void)undo
{
//    [super undo];
    @try {
        [super undo];
    }
    @catch (NSException *exception) {
        [self removeAllActions];
    }
    @finally {
        
    }
    
    gNeedSave = YES;
}

- (void)redo
{
//    [super redo];
    @try {
        [super redo];
    }
    @catch (NSException *exception) {
        [self removeAllActions];
    }
    @finally {
        
    }
    gNeedSave = YES;
}

- (void)undoNestedGroup
{
    @try {
        [super undoNestedGroup];
    }
    @catch (NSException *exception) {
        [self removeAllActions];
    }
    @finally {
        
    }
    gNeedSave = YES;
}

-(void)removeAllActionsWithTarget:(id)target
{
    [super removeAllActionsWithTarget:target];
    int a = 0;
}
@end
