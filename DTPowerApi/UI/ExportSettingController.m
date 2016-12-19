//
//  ExportSettingController.m
//  DTPowerApi
//
//  Created by leks on 13-2-12.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "ExportSettingController.h"
#import "PAExportEngine.h"
#import "PATableHeaderCellView.h"
#import "PATableRowView.h"
#import "DTUtil.h"

#define EXPORT_LAST_PLATFORM @"EXPORT_LAST_PLATFORM"
#define EXPORT_LAST_PATH     @"EXPORT_LAST_PATH"

@interface ExportSettingController ()

@end

@implementation ExportSettingController
@synthesize projects;
@synthesize selectedProject;
@synthesize currentApis;
@synthesize currentBeans;

-(void)dealloc
{
    [projects release];
    [selectedProject release];
    [currentApis release];
    [currentBeans release];
    [super dealloc];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    if (selectedProject)
    {
        [projectCombo setStringValue:selectedProject.name];
    }
    else
    {
        self.selectedProject = [self.projects objectAtIndex:0];
    }
    
    if (currentApis)
    {
        NSMutableIndexSet *mindexset = [NSMutableIndexSet indexSet];
        for (int i=0; i<currentApis.count; i++) {
            id api = [currentApis objectAtIndex:i];
            NSUInteger idx = [self.selectedProject.apis.allChildren indexOfObject:api];
            [mindexset addIndex:idx];
        }
        
        [apisTable selectRowIndexes:mindexset byExtendingSelection:NO];
        if (currentApis.count == self.selectedProject.apis.allChildren.count)
        {
            [allApiCheck setState:1];
        }
        else
        {
            [allApiCheck setState:0];
        }
    }
    
    if (currentBeans)
    {
        NSMutableIndexSet *mindexset = [NSMutableIndexSet indexSet];
        for (int i=0; i<currentBeans.count; i++) {
            id bean = [currentBeans objectAtIndex:i];
            NSUInteger idx = [self.selectedProject.beans.allChildren indexOfObject:bean];
            [mindexset addIndex:idx];
        }
        
        [beansTable selectRowIndexes:mindexset byExtendingSelection:NO];
        
        if (currentBeans.count == self.selectedProject.beans.allChildren.count)
        {
            [allBeanCheck setState:1];
        }
        else
        {
            [allBeanCheck setState:0];
        }
    }
    
    NSTableHeaderView *beanHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 31)];
    [beansTable setHeaderView:beanHeaderView];
    [beansTable setCornerView:nil];
    [beanHeaderView release];
    
    beanHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 31)];
    [apisTable setHeaderView:beanHeaderView];
    [apisTable setCornerView:nil];
    [beanHeaderView release];
    
    for (NSTableColumn *column in [beansTable tableColumns])
    {
        PATableHeaderCellView *cell = [[[PATableHeaderCellView alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
    
    for (NSTableColumn *column in [apisTable tableColumns])
    {
        PATableHeaderCellView *cell = [[[PATableHeaderCellView alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
    
    NSString *last_platform = USER_DEFAULTS_GET(EXPORT_LAST_PLATFORM);
    if (last_platform)
    {
        if (last_platform.integerValue == 0)
        {
            ;
        }
    }
    
    NSString *objcChecked = USER_DEFAULTS_GET(@"DTAPI_EXPORT_OBJCCHECKED");
    NSString *javaChecked = USER_DEFAULTS_GET(@"DTAPI_EXPORT_JAVACHECKED");

    if (objcChecked)
    {
        [iosCheck setState:1];
    }

    if (javaChecked)
    {
        [androidCheck setState:1];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (notification.object == apisTable)
    {
        NSUInteger scount = [[apisTable selectedRowIndexes] count];
        if (scount == self.selectedProject.apis.allChildren.count) {
            [allApiCheck setState:1];
        }
        else
        {
            [allApiCheck setState:0];
        }
    }
    else if (notification.object == beansTable)
    {
        NSUInteger scount = [[beansTable selectedRowIndexes] count];
        if (scount == self.selectedProject.beans.allChildren.count) {
            [allBeanCheck setState:1];
        }
        else
        {
            [allBeanCheck setState:0];
        }
    }
}

-(IBAction)checkApisAction:(id)sender
{
    if (allApiCheck.state == 0)
    {
        [apisTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    }
    else
    {
        [apisTable selectAll:nil];
    }
}

-(IBAction)checkBeansAction:(id)sender
{
    if (allBeanCheck.state == 0)
    {
        [beansTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    }
    else
    {
        [beansTable selectAll:nil];
    }
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    self.selectedProject = [self.projects objectAtIndex:[projectCombo indexOfSelectedItem]];
}

-(IBAction)exportAction:(id)sender
{
    if (iosCheck.state == 0 &&
        androidCheck.state == 0) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Please select a platform first!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
        [alert runModal];
        return ;
    }
    NSMutableArray *export_beans = [NSMutableArray arrayWithCapacity:10];
    NSMutableArray *export_apis = [NSMutableArray arrayWithCapacity:10];
    
    NSString *selected_project_name = [projectCombo stringValue];
    PAProject *selected_project = nil;
    for (int i=0; i<projects.count; i++)
    {
        PAProject *p = [projects objectAtIndex:i];
        if ([selected_project_name isEqualToString:p.name]) {
            selected_project = p;
            break;
        }
    }
    
    NSIndexSet *beans_indexes = [beansTable selectedRowIndexes];
    [beans_indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [export_beans addObject:[selected_project.beans.allChildren objectAtIndex:idx]];
    }];
    
    NSIndexSet *apis_indexes = [apisTable selectedRowIndexes];
    [apis_indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [export_apis addObject:[selected_project.apis.allChildren objectAtIndex:idx]];
    }];
    
    NSString *export_path = nil;
    
    if (pathField.stringValue.length > 0) {
        export_path = pathField.stringValue;
    }
    else
    {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        openPanel.canChooseDirectories = YES;
        openPanel.canChooseFiles = NO;
        openPanel.allowsMultipleSelection = NO;
        NSUInteger result = [openPanel runModal];
        if (result == NSFileHandlingPanelOKButton)
        {
            export_path = pathField.stringValue = openPanel.URL.path;
        }
        else
        {
            return ;
        }
    }
    
    if (export_beans.count > 0 && iosCheck.state == 1) {
        [PAExportEngine exportBeans:export_beans inProject:selected_project toFolderPath:export_path withTemplate:kPATemplateBeanIOS];
    }
    
    if (export_apis.count > 0 && iosCheck.state == 1) {
        [PAExportEngine iOSExportApis:export_apis inProject:selected_project toFolderPath:export_path];
    }
    
    if (export_beans.count > 0 && androidCheck.state == 1) {
        [PAExportEngine exportBeans:export_beans inProject:selected_project toFolderPath:export_path withTemplate:kPATemplateBeanJAVA];
    }
    
    if (export_apis.count > 0 && androidCheck.state == 1) {
        [PAExportEngine javaExportApis:export_apis inProject:selected_project toFolderPath:export_path];
    }
    NSAlert *alert = [NSAlert alertWithMessageText:@"Export finished!" defaultButton:@"OK" alternateButton:nil otherButton:@"Show in Finder" informativeTextWithFormat:@""];
    NSInteger result = [alert runModal];
    
    if (result == NSAlertDefaultReturn) {
        ;
    }
    else if (result == NSAlertOtherReturn)
    {
        NSString *show_path = [NSString stringWithFormat:@"file:%@/%@", export_path, selected_project.name];
        NSURL *showURL = [NSURL URLWithString:show_path];
        NSArray *fileURLs = [NSArray arrayWithObjects:showURL, nil];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
    }
    
    if (iosCheck.state == 1)
    {
        USER_DEFAULTS_SAVE(@"1", @"DTAPI_EXPORT_OBJCCHECKED");
    }
    else if (iosCheck.state == 0)
    {
        USER_DEFAULTS_REMOVE(@"DTAPI_EXPORT_OBJCCHECKED");
    }
    
    if (androidCheck.state == 1)
    {
        USER_DEFAULTS_SAVE(@"1", @"DTAPI_EXPORT_JAVACHECKED");
    }
    else if (androidCheck.state == 0)
    {
        USER_DEFAULTS_REMOVE(@"DTAPI_EXPORT_JAVACHECKED");
    }

    [self closeWindow:nil];
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    PATableRowView *rowview = [[PATableRowView alloc] init];
    rowview.gridColor = tableView.gridColor;
    rowview.parentTableView = tableView;
    return [rowview autorelease];
}

- (BOOL)windowShouldClose:(id)sender
{
    [[NSApplication sharedApplication] stopModal];

    return YES;
}

-(IBAction)closeWindow:(id)sender
{
    [[NSApplication sharedApplication] stopModal];
    [self close];
}

-(IBAction)choosePathAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    openPanel.allowsMultipleSelection = NO;
    NSUInteger result = [openPanel runModal];
    if (result == NSFileHandlingPanelOKButton)
    {
        pathField.stringValue = openPanel.URL.path;
    }
}
@end
