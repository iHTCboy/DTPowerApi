//
//  PAWindowController.h
//  DTPowerApi
//
//  Created by leks on 12-12-27.
//  Copyright (c) 2012年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProjectPanelViewController.h"
#import "ProjectDetailViewController.h"
#import "BasicInfoView.h"
#import "ApiDetailViewController.h"
#import "BeanDetailViewController.h"
#import "DataMappingViewController.h"
#import "BackgroundView.h"
#import "PASplitView.h"

@interface PAWindowController : NSWindowController<NSWindowDelegate, NSSplitViewDelegate, NSToolbarDelegate>
{
    NSSplitView *container;
    IBOutlet NSView *left;
    IBOutlet BackgroundView *middle;
    IBOutlet NSView *right;
    
    ProjectPanelViewController *projectPanelController;
    ProjectDetailViewController *projectDetailController;
    ApiDetailViewController *apiDetailController;
    BeanDetailViewController *beanDetailController;
    DataMappingViewController *dataMappingController;
    
    IBOutlet BasicInfoView *basicInfoView;
    IBOutlet NSView *inspector;
    
    NSURL *_saveURL;
    
    IBOutlet NSToolbarItem *startApiItem;
    IBOutlet NSToolbarItem *stopApiItem;
    IBOutlet NSToolbarItem *startAllApiItem;
    
    IBOutlet NSToolbarItem *addMappingItem;
    IBOutlet NSToolbarItem *removePropertyItem;
    IBOutlet NSToolbarItem *createObjectItem;
    IBOutlet NSToolbarItem *smartItem;
    
    IBOutlet NSToolbarItem *exportItem;
    BOOL inspectorExpanded;
    BOOL outlineExpanded;
    BOOL logExpanded;
    
    id currentItem;
    
    NSMutableArray *selectedObjects;
    
    IBOutlet NSImageView *rightSepline;
    IBOutlet NSImageView *leftSepline;
    
    IBOutlet NSSegmentedCell *segment;
    
    BOOL saving;
    
    NSString *openPath;
}
@property (nonatomic, retain) IBOutlet NSSplitView *container;
@property (nonatomic, retain) ProjectPanelViewController *projectPanelController;
@property (nonatomic, retain) ProjectDetailViewController *projectDetailController;
@property (nonatomic, retain) ApiDetailViewController *apiDetailController;
@property (nonatomic, retain) BeanDetailViewController *beanDetailController;
@property (nonatomic, retain) DataMappingViewController *dataMappingController;
@property (nonatomic, retain) id currentItem;
@property (nonatomic, retain) NSURL *saveURL;
@property (nonatomic, retain) NSMutableArray *selectedObjects;
@property (nonatomic, copy) NSString *openPath;

-(void)reloadMenuStatus;
-(void)disableMappingMenus;
-(void)reloadMappingMenuStatus;
-(BOOL)openFile:(NSString*)filepath;
@end
