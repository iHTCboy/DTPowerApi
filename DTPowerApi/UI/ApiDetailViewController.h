//
//  ApiDetailViewController.h
//  DTPowerApi
//
//  Created by leks on 13-1-14.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAApi.h"
#import "ProjectTextField.h"
#import "ParamEditController.h"
#import "BasicInfoView.h"
#import "BackgroundView.h"

@interface ApiDetailViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate, ProjectTextFieldDelegate, ParamEditDelegate>
{
    PAApi *api;
    IBOutlet NSTextField *baseUrl;
    IBOutlet NSTextField *path;
    IBOutlet NSTableView *paramsTable;
    IBOutlet NSTableView *datasTable;
    IBOutlet NSTextView *previewView;
    
    ParamEditController *paramEditController;
    ParamEditController *postParamEditController;
    
    IBOutlet NSScrollView *container;
    IBOutlet NSView *contentView;

    IBOutlet BasicInfoView *basicInfoView;
    
    IBOutlet NSTableView *paramGroupsTable;
    IBOutlet NSTableView *resultTable;
    
    IBOutlet NSButton *dupSelectedBtn;
    IBOutlet NSButton *autoCreateResultBtn;
    
    BOOL fromSelf;
    BOOL addingResult;
    BOOL addingParamGroup;
    
    IBOutlet NSArrayController *getParamArrayController;
    IBOutlet NSArrayController *postDataArrayController;
    IBOutlet NSArrayController *paramGroupArrayController;
    IBOutlet NSArrayController *resultsGroupArrayController;
    
    NSUInteger currentTabIndex;
    NSUInteger currentBottomTabIndex;
    
    IBOutlet NSView *apiView;
    IBOutlet NSButton *upTabBtn;
    IBOutlet NSButton *bottomTabBtn;
    IBOutlet NSImageView *bg;
    IBOutlet NSImageView *bottomBg;
    
    IBOutlet NSView *resultView;
    IBOutlet NSView *paramGroupsView;
}
@property (nonatomic, retain) PAApi *api;
@property (nonatomic, retain) ParamEditController *paramEditController;
@property (nonatomic, retain) ParamEditController *postParamEditController;

-(IBAction)editGetParamAction:(id)sender;
-(IBAction)editPostDataAction:(id)sender;

- (void)scrollToTop;

-(void)reloadApi:(PAApi*)newApi;
@end
