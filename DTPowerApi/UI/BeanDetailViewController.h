//
//  BeanDetailViewController.h
//  DTPowerApi
//
//  Created by leks on 13-1-22.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PABean.h"
#import "PropertyWindowController.h"
#import "BasicInfoView.h"
#import "PAValidationTextField.h"

@interface BeanDetailViewController : NSViewController<PropertyWindowDelegate>
{
    PABean *bean;
    IBOutlet NSScrollView *container;
    IBOutlet PAValidationTextField *beanName;
    IBOutlet NSTableView *propertyTable;
    IBOutlet BasicInfoView *basicInfoView;
    IBOutlet NSTableView *connectedApiTable;
    
    PropertyWindowController *editPropertyController;
    NSMutableArray *connectedApis;
    
    NSArrayController *contents;
    NSArrayController *connectedApisArrayController;
    
    IBOutlet NSImageView *bg;
    
    IBOutlet NSView *beanView;
    IBOutlet NSButton *tabBtn;
    IBOutlet NSTextField *commonLabel;
    IBOutlet NSTextField *beanLabel;
    NSUInteger currentTabIndex;
    
//    IBOutlet NSArrayController *propertiesArrayController;
//    IBOutlet NSArrayController *connectedApiArrayController;
}
@property (nonatomic, retain) PABean *bean;
@property (nonatomic, retain) PropertyWindowController *editPropertyController;
@property (nonatomic, retain) NSMutableArray *connectedApis;
@property (nonatomic, retain) IBOutlet NSArrayController *contents;
@property (nonatomic, retain) IBOutlet NSArrayController *connectedApisArrayController;
-(void)reloadFieldItems;
- (void)scrollToTop;
-(void)reloadBean:(PABean*)newBean;
@end
