//
//  ProjectOutlineView.h
//  DTPowerApi
//
//  Created by leks on 13-1-7.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ProjectOutlineView;

@protocol ProjectOutlineViewDelegate <NSObject>

-(void)outlineView:(ProjectOutlineView*)outlineView pasteItem:(id)item;
-(void)outlineView:(ProjectOutlineView*)outlineView cutItem:(id)item;
-(void)outlineView:(ProjectOutlineView*)outlineView deleteItem:(id)item;

@end

@interface ProjectOutlineView : NSOutlineView
{
    id <ProjectOutlineViewDelegate> projectDelegate;
}
@property (nonatomic, assign) IBOutlet id <ProjectOutlineViewDelegate> projectDelegate;
@end
