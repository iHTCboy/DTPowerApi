//
//  ParamEditController.h
//  DTPowerApi
//
//  Created by leks on 13-1-17.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAParam.h"

@class ParamEditController;
@class PAProject;

@protocol ParamEditDelegate <NSObject>

-(void)paramEditDidFinished:(ParamEditController*)editController;

@end

@interface ParamEditController : NSWindowController<NSWindowDelegate, NSComboBoxDataSource, NSComboBoxDelegate>
{
    PAParam *param;
    
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *keyField;
    
    IBOutlet NSTextView *filepath;
    IBOutlet NSComboBox *types;
    
    IBOutlet NSTextView *valueView;
    IBOutlet NSTextField *comment;
    IBOutlet NSButton *browserBtn;
    
    id<ParamEditDelegate> pEditDelegate;
    NSUndoManager *pUndoManager;
    
    BOOL projectMode;
    PAProject *project;
}
@property (nonatomic, retain) PAParam *param;
@property (nonatomic, assign) IBOutlet id<ParamEditDelegate> pEditDelegate;
@property (nonatomic, retain) NSUndoManager *pUndoManager;
@property (nonatomic) BOOL projectMode;
@property (nonatomic, retain) PAProject *project;

-(void)reloadParam:(PAParam*)p;
@end
