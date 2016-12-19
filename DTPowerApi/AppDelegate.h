//
//  AppDelegate.h
//  DTPowerApi
//
//  Created by leks on 12-12-26.
//  Copyright (c) 2012年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PAWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    PAWindowController *window;
    IBOutlet NSMenuItem *projectNavigatorItem;
    IBOutlet NSMenuItem *logPanelItem;
    IBOutlet NSMenuItem *inspectorItem;
    
    IBOutlet NSMenuItem *addProjectItem;
    IBOutlet NSMenuItem *addApiItem;
    IBOutlet NSMenuItem *addBeanItem;
}

-(void)reloadItem:(NSUInteger)tag title:(NSString*)title;
@end
