//
//  DataMappingViewController.h
//  DTPowerApi
//
//  Created by leks on 13-1-23.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAApi.h"
#import "BeanTypeCellView.h"
#import "BackgroundView.h"

@interface DataMappingViewController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate, BeanTypeCellDelegate, NSSplitViewDelegate>
{
    PAApi *api;
    IBOutlet NSSplitView *analyzerContainer;
    IBOutlet NSOutlineView *jsonOutlineView;
    IBOutlet NSOutlineView *beanOutlineView;
    
    IBOutlet NSScrollView *jsonScrollView;
    IBOutlet NSScrollView *beanScrollView;
    
    IBOutlet NSView *beanBgView;
    IBOutlet NSView *jsonBgView;
    
    IBOutlet NSTextView *log;
    IBOutlet NSView *responseView;
    IBOutlet NSImageView *responseBg;
    IBOutlet NSImageView *responseSubBg1;
    IBOutlet NSImageView *responseSubBg2;
    
    BOOL fromAutoExpand;
    IBOutlet NSSegmentedControl *segment;
    
    IBOutlet BackgroundView *allBg;
    
    IBOutlet NSImageView *beanBackground;
    IBOutlet NSImageView *jsonBackground;
    
    NSUInteger currentTabIndex;
    IBOutlet NSButton *tabBtn;
    IBOutlet NSImageView *logBg;
    IBOutlet NSTextView *responseTextView;
}
@property (nonatomic, retain) PAApi *api;
@property (nonatomic, readonly) NSOutlineView *jsonOutlineView;
@property (nonatomic, readonly) NSOutlineView *beanOutlineView;

-(void)startApi;
-(void)mappingField;
-(void)removeProperty;
-(void)createBeanObject;
-(void)smartAction;
-(void)reloadResponseString;
@end
