//
//  ProjectPanelViewController.h
//  DTPowerApi
//
//  Created by leks on 13-1-5.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProjectTextField.h"
#import "ProjectCellView.h"
#import "ProjectOutlineView.h"

typedef enum _ProjectMenuType {
    PROJECT_MENU_ROOT,
    PROJECT_MENU_PROJECT,
    PROJECT_MENU_APIFOLDER,
    PROJECT_MENU_BEANFOLDER,
    PROJECT_MENU_API,
    PROJECT_MENU_BEAN
}ProjectMenuType;

@interface ProjectPanelViewController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate, NSMenuDelegate, NSAlertDelegate, NSTextViewDelegate, NSControlTextEditingDelegate, ProjectOutlineViewDelegate>
{
    ProjectOutlineView *_projectPanel;
    IBOutlet NSMenu *projectMenu;
    IBOutlet NSSearchField *_searchField;
    IBOutlet NSScrollView *_projectContainer;
    
    ProjectMenuType _menuType;
    
    NSMutableArray *projects;
    NSMutableArray *allProjects;
    
    IBOutlet NSButton *addBtn;
    IBOutlet NSButton *removeBtn;
    
    NSURL *savedURL;
    
    NSMutableIndexSet *selection;
    BOOL fromAutoExpand;
    
    BOOL isAdding;
    BOOL isRemoving;
}
@property (nonatomic, retain) IBOutlet ProjectOutlineView *projectPanel;
@property (nonatomic, retain) NSMutableArray *projects;
@property (nonatomic, retain) NSMutableArray *allProjects;
@property (nonatomic, retain) NSURL *savedURL;
@property (nonatomic, retain) NSMutableIndexSet *selection;

-(void)reloadProjects:(NSArray*)newProjects;
-(void)exportBeanAction;
-(void)exportAllBeansAction;

-(void)insertProjects:(NSArray *)array;
-(void)removeProjects:(NSArray *)array;
-(BOOL)projectMenuValidate:(NSUInteger)tag;

-(void)addProjectFromMenu;
-(void)addApiFromMenu;
-(void)addBeanFromMenu;

-(void)addApiFromTopMenu;
-(void)addBeanFromTopMenu;
@end
