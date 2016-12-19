//
//  PropertyWindowController.h
//  DTPowerApi
//
//  Created by leks on 13-1-29.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAProperty.h"

@class PropertyWindowController;
@class PAProject;

@protocol PropertyWindowDelegate <NSObject>

-(void)propertyEditDidFinished:(PropertyWindowController*)editController;

@end

@interface PropertyWindowController : NSWindowController<NSComboBoxDataSource, NSComboBoxDelegate>
{
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *keyField;
    IBOutlet NSComboBox *typeCombo;
    IBOutlet NSComboBox *beanCombo;
    IBOutlet NSTextField *defaultField;
    IBOutlet NSTextField *commentView;
    
    PAProperty *property;
    PAProject *project;
    
    id<PropertyWindowDelegate> proDelegate;
    
    BOOL firstEdit;
    BOOL edited;
}
@property (nonatomic, retain) PAProperty *property;
@property (nonatomic, retain) PAProject *project;
@property (nonatomic, assign) id<PropertyWindowDelegate> proDelegate;
@property (nonatomic) BOOL firstEdit;

-(void)reloadProperty:(PAProperty*)p;
@end
