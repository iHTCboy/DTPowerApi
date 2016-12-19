//
//  ProjectOutlineView.m
//  DTPowerApi
//
//  Created by leks on 13-1-7.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "ProjectOutlineView.h"
#import "PAProject.h"
#import "PAApi.h"
#import "PABean.h"
#import "JSON.h"

@implementation ProjectOutlineView
@synthesize projectDelegate;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(IBAction)copy:(id)sender
{
    NSIndexSet *selectedIndexes = self.selectedRowIndexes;
    
    if (selectedIndexes.count > 0)
    {
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            id item = [self itemAtRow:idx];
            if ([item isKindOfClass:[PABean class]])
            {
                [ma addObject:[item copyDict]];
            }
            else
            {
                [ma addObject:[item toDict]];
            }
        }];
        
        NSMutableString *ms = [NSMutableString stringWithCapacity:1000];
        [ms setString:[ma JSONRepresentation]];
        
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        NSArray *copiedObjects = [NSArray arrayWithObject:ms];
        [pasteboard writeObjects:copiedObjects];
    }
}

-(IBAction)paste:(id)sender
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[NSString class]];
    NSDictionary *options = [NSDictionary dictionary];
    
    BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];
    if (ok)
    {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        NSString *jsonString = [objectsToPaste objectAtIndex:0];
        if ([projectDelegate respondsToSelector:@selector(outlineView:pasteItem:)])
        {
            if (jsonString)
            {
                [projectDelegate outlineView:self pasteItem:jsonString];
            }
        }
    }
}

-(IBAction)cut:(id)sender
{
    [self copy:nil];
    if ([projectDelegate respondsToSelector:@selector(outlineView:cutItem:)])
    {
        [projectDelegate outlineView:self cutItem:nil];
    }
}

-(IBAction)delete:(id)sender
{
    if ([projectDelegate respondsToSelector:@selector(outlineView:deleteItem:)])
    {
        [projectDelegate outlineView:self deleteItem:nil];
    }
}

//- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem {
//    
//    if ([anItem action] == @selector(paste:)) {
//        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
//        NSArray *classArray = [NSArray arrayWithObject:[NSImage class]];
//        NSDictionary *options = [NSDictionary dictionary];
//        return [pasteboard canReadObjectForClasses:classArray options:options];
//    }
//    return [super validateUserInterfaceItem:anItem];
//}

- (BOOL)shouldCollapseAutoExpandedItemsForDeposited:(BOOL)deposited
{
//    NSLog(@"deposited:%d", deposited);
    if (deposited) {
        return NO;
    }
    return YES;
}
@end
