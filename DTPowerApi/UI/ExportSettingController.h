//
//  ExportSettingController.h
//  DTPowerApi
//
//  Created by leks on 13-2-12.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAProject.h"
#import "PAApiFolder.h"
#import "PAApi.h"
#import "PABean.h"
#import "PABeanFolder.h"
#import "PATableView.h"

@interface ExportSettingController : NSWindowController<NSComboBoxDelegate, NSTableViewDelegate>
{
    IBOutlet NSButton *iosCheck;
    IBOutlet NSButton *androidCheck;
    IBOutlet NSButton *withCommentCheck;
    IBOutlet NSButton *allBeanCheck;
    IBOutlet NSButton *allApiCheck;
    
    IBOutlet NSButton *exportBtn;
    IBOutlet NSButton *cancelBtn;
    
    IBOutlet PATableView *beansTable;
    IBOutlet PATableView *apisTable;
    
    IBOutlet NSComboBox *projectCombo;
    
    IBOutlet NSTextField *pathField;
    NSArray *projects;
    PAProject *selectedProject;
    
    NSArray *currentApis;
    NSArray *currentBeans;
}
@property (nonatomic, retain) NSArray *projects;
@property (nonatomic, retain) PAProject *selectedProject;
@property (nonatomic, retain) NSArray *currentApis;
@property (nonatomic, retain) NSArray *currentBeans;
@end
