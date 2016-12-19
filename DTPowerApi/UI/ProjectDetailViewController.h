//
//  ProjectDetailViewController.h
//  DTPowerApi
//
//  Created by leks on 13-1-14.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAProject.h"
#import "ProjectTextField.h"
#import "BasicInfoView.h"
#import "PATableView.h"
#import "BorderScrollView.h"
#import "ParamEditController.h"

@interface ProjectDetailViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate, ParamEditDelegate>
{
    PAProject *project;
    IBOutlet NSTextField *baseUrl;
    IBOutlet NSTextField *websiteUrl;
    IBOutlet PATableView *apisTable;
    IBOutlet PATableView *beansTable;
    IBOutlet NSScrollView *container;
    IBOutlet BasicInfoView *basicInfoView;
    
    IBOutlet NSImageView *bg;
    
    IBOutlet NSView *projectView;
    IBOutlet NSButton *tabBtn;
    IBOutlet NSTextField *commonLabel;
    IBOutlet NSTextField *projectLabel;
    NSUInteger currentTabIndex;
    
    IBOutlet NSArrayController *apisArrayController;
    IBOutlet NSArrayController *beansArrayController;
    
    IBOutlet BorderScrollView *apisScrollView;
    IBOutlet BorderScrollView *beansScrollView;
    
    IBOutlet PATableView *commonParamsTable;
    IBOutlet PATableView *commonDatasTable;
    
    ParamEditController *paramEditController;
    ParamEditController *postParamEditController;
    
    IBOutlet NSArrayController *commonGetArrayController;
    IBOutlet NSArrayController *commonPostArrayController;
}
@property (nonatomic, retain) PAProject *project;
@property (nonatomic, retain) ParamEditController *paramEditController;
@property (nonatomic, retain) ParamEditController *postParamEditController;
//-(void)reloadFieldItems;

-(IBAction)tabAction:(id)sender;

-(void)reloadProject:(PAProject*)newProject;
@end
