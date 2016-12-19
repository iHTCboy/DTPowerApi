//
//  ProjectPanelViewController.m
//  DTPowerApi
//
//  Created by leks on 13-1-5.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "ProjectPanelViewController.h"
#import "PAProject.h"
#import "PAApi.h"
#import "PABean.h"
#import "Global.h"
#import "PAExportEngine.h"
#import "DTUtil.h"
#import "JSON.h"
#import "PAMappingEngine.h"
#import "ProjectTableRowView.h"
#import "BackgroundView.h"
#import "PAUndoManager.h"
#import "PAParam.h"
#import "PAParamGroup.h"

@interface ProjectPanelViewController ()

@end

@implementation ProjectPanelViewController
@synthesize projects;
@synthesize allProjects;
@synthesize projectPanel = _projectPanel;
@synthesize savedURL;
@synthesize selection;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [projects release];
    [allProjects release];
    [_projectPanel release];
    [savedURL release];
    [selection release];
    [super dealloc];
}

-(void)loadView
{
    [super loadView];

//    BackgroundView *bgview = (BackgroundView*)self.view;
//    [bgview setBackgroundImage:[NSImage imageNamed:@"projectpanel_bg"]];
    
    self.selection = [NSMutableIndexSet indexSet];
    [self reloadProjects:nil];

//    USER_DEFAULTS_REMOVE(@"DTAPI_ALREADY_EXECUTED");
    NSString *alreadyExecuted = USER_DEFAULTS_GET(@"DTAPI_ALREADY_EXECUTED");
    if (!alreadyExecuted)
    {
        PAProject *helloworld = [GlobalSetting helloworldProject];
        if (helloworld) {
            [self reloadProjects:[NSArray arrayWithObject:helloworld]];
        }
        [gWindowController reloadMappingMenuStatus];
        [gWindowController reloadMenuStatus];
        
        USER_DEFAULTS_SAVE(@"1", @"DTAPI_ALREADY_EXECUTED");
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
               selector:@selector(outlineViewItemDidExpand:)
                   name:NSOutlineViewItemDidExpandNotification
                 object:_projectPanel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
               selector:@selector(outlineViewItemDidCollapse:)
                   name:NSOutlineViewItemDidCollapseNotification
                 object:_projectPanel];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionChanged:)
                                                 name:NSOutlineViewSelectionDidChangeNotification object:_projectPanel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controlTextChanged:)
                                                 name:NSControlTextDidChangeNotification object:_searchField];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(projectBeansChanged:)
                                                 name:PANOTIFICATION_PROJECT_BEANS_CHANGED
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(projectsChanged:)
                                                 name:PANOTIFICATION_PROJECTROOT_CHANGED
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(projectApisChanged:)
                                                 name:PANOTIFICATION_PROJECT_APIS_CHANGED
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(apiChildrenChanged:)
                                                 name:PANOTIFICATION_API_CHILDREN_CHANGED
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(beanChildrenChanged:)
                                                 name:PANOTIFICATION_BEAN_CHILDREN_CHANGED
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(apiStatusChanged:)
                                                 name:PANOTIFICATION_API_STATUS_CHANGED
                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserverForName:NSUndoManagerDidOpenUndoGroupNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//        NSUndoManager *undo = note.object;
//        NSLog(@"open");
//    }];
//    
//    [[NSNotificationCenter defaultCenter] addObserverForName:NSUndoManagerCheckpointNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//        NSUndoManager *undo = note.object;
//        NSLog(@"%@", undo.undoActionName);
//    }];
//    
//    [[NSNotificationCenter defaultCenter] addObserverForName:NSUndoManagerDidCloseUndoGroupNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//        NSUndoManager *undo = note.object;
//        NSLog(@"close");
//    }];
//
    [_projectPanel registerForDraggedTypes:[NSArray
                                          arrayWithObject:NSPasteboardTypeString]];
    [_projectPanel setNeedsDisplay];
}

-(void)reloadProjects:(NSArray*)newProjects
{
    self.projects = [NSMutableArray arrayWithCapacity:10];
    [self.projects addObject:@"Projects"];
    self.allProjects = [NSMutableArray arrayWithCapacity:10];
    [self.allProjects addObject:@"Projects"];
    
    if (newProjects) {
        [self.allProjects addObjectsFromArray:newProjects];
        [self.projects addObjectsFromArray:newProjects];
        for (int i=1; i<self.allProjects.count; i++) {
            PAProject *pj = [self.allProjects objectAtIndex:i];
            pj.rowIndex = i-1;
            pj.allProjectsRefs = self.allProjects;
        }
    }
    
    // The basic recipe for a sidebar. Note that the selectionHighlightStyle is set to NSTableViewSelectionHighlightStyleSourceList in the nib
    [_projectPanel sizeLastColumnToFit];
    [_projectPanel reloadData];
    [_projectPanel setFloatsGroupRows:NO];
    
    // NSTableViewRowSizeStyleDefault should be used, unless the user has picked an explicit size. In that case, it should be stored out and re-used.
    [_projectPanel setRowSizeStyle:NSTableViewRowSizeStyleCustom];
    
    [self reloadTables];
}

-(void)reloadTables
{
    NSInteger last_select_row = _projectPanel.selectedRow;
    CGFloat tmp_y = [gGlobalSetting.lastResultYOffset floatValue];
    [_projectPanel reloadItem:nil reloadChildren:YES];
    [self reloadExpandedItems];
    gGlobalSetting.lastResultYOffset = [NSString stringWithFormat:@"%f", tmp_y];
    [self reloadLastOffsetY];
    [_projectPanel selectRowIndexes:[NSIndexSet indexSetWithIndex:last_select_row] byExtendingSelection:NO];
}

-(void)reloadLastOffsetY
{
    CGFloat last_y_offset = [gGlobalSetting.lastResultYOffset floatValue];
    NSRect jsr = _projectContainer.contentView.bounds;
    jsr.origin.y = last_y_offset;
    _projectContainer.contentView.bounds = jsr;
}

-(void)reloadExpandedItems
{
    fromAutoExpand = YES;
    for (int i=1; i<self.projects.count;i++)
    {
        PAProject *pj = [self.projects objectAtIndex:i];
        if (pj.expanded)
        {
            [_projectPanel expandItem:pj];
            if (pj.beans.expanded) {
                [_projectPanel expandItem:pj.beans];
            }
            
            if (pj.apis.expanded) {
                [_projectPanel expandItem:pj.apis];
            }
        }
    }
    fromAutoExpand = NO;
//    for (int i=0;i<gGlobalSetting.expandedItems.count; i++)
//    {
//        NSString *itemIndex = [gGlobalSetting.expandedItems objectAtIndex:i];
//        if (itemIndex.integerValue < _projectPanel.numberOfRows)
//        {
//            [_projectPanel expandItem:[_projectPanel itemAtRow:itemIndex.integerValue]];
//        }
//    }
}

#pragma mark -
#pragma mark ***** NSOutlineView Required Methods (unless bindings are used) *****

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil)
    {
        return self.projects.count;
    }
    else if (item == [self.projects objectAtIndex:0])
    {
        return 0;
    }
    else if ([item isKindOfClass:[PAProject class]])
    {
        return 2;
    }
    else if ([item isKindOfClass:[PAApiFolder class]])
    {
        PAApiFolder *apis = (PAApiFolder*)item;
        return apis.children.count;
    }
    else if ([item isKindOfClass:[PABeanFolder class]])
    {
        PABeanFolder *beans = (PABeanFolder*)item;
        return beans.children.count;
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item) {
        return [self.projects objectAtIndex:index];
    }
    else if (item == [self.projects objectAtIndex:0])
    {
        return [self.projects objectAtIndex:index+1];
    }
    else if ([item isKindOfClass:[PAProject class]])
    {
        id tt = nil;
        PAProject *pj = (PAProject*)item;
        
        if (index == 0)
        {
            tt = pj.apis;
        }
        else if (index == 1)
        {
            tt = pj.beans;
        }
        
        return tt;
    }
    else if ([item isKindOfClass:[PAApiFolder class]])
    {
        PAApiFolder *apis = (PAApiFolder*)item;
        return [apis.children objectAtIndex:index];
    }
    else if ([item isKindOfClass:[PABeanFolder class]])
    {
        PABeanFolder *beans = (PABeanFolder*)item;
        return [beans.children objectAtIndex:index];
    }
    
    return @"1";
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (!item) {
        return YES;
    }
    else if (item == [self.projects objectAtIndex:0])
    {
        return NO;
    }
    else if ([item isKindOfClass:[PAProject class]])
    {
        return YES;
    }
    else if ([item isKindOfClass:[PAApiFolder class]])
    {
        PAApiFolder *apis = (PAApiFolder*)item;
        if (apis.children.count > 0) {
            return YES;
        }
    }
    else if ([item isKindOfClass:[PABeanFolder class]])
    {
        PABeanFolder *beans = (PABeanFolder*)item;
        if (beans.children.count > 0) {
            return YES;
        }
    }
    
    return NO;
}

//- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
//    return item == [self.projects objectAtIndex:0];
//}
- (NSIndexSet *)outlineView:(NSOutlineView *)outlineView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
    if ([proposedSelectionIndexes count] == 1)
    {
        [self.selection removeAllIndexes];
        [self.selection addIndexes:proposedSelectionIndexes];
    }
    else
    {
        __block BOOL sametype = YES;
        NSMutableIndexSet *mindexSet = [NSMutableIndexSet indexSet];
        
        [proposedSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger nidx, BOOL *nstop)
        {
            id newitem = [outlineView itemAtRow:nidx];
            __block BOOL exists = NO;
            [self.selection enumerateIndexesUsingBlock:^(NSUInteger eidx, BOOL *estop){
                if (nidx == eidx) {
                    exists = YES;
                }
                id existsItem = [outlineView itemAtRow:eidx];
                if ([newitem class] != [existsItem class])
                {
                    sametype = NO;
                }
            }];
            if (!exists) {
                [mindexSet addIndex:nidx];
            }
        }];
        
        if (sametype)
        {
            
            id sitem = [_projectPanel itemAtRow:[self.selection firstIndex]];
            id nitem = [_projectPanel itemAtRow:[mindexSet lastIndex]];
            
            if ([sitem isKindOfClass:[PAApi class]] ||
                [sitem isKindOfClass:[PABean class]] ||
                [sitem isKindOfClass:[PAApiFolder class]] ||
                [sitem isKindOfClass:[PABeanFolder class]])
            {
                if ([sitem project] != [nitem project])
                {
                    sametype = NO;
                }
            }
            
            if (sametype) {
                [self.selection removeAllIndexes];
                [self.selection addIndexes:proposedSelectionIndexes];
            }
        }
    }
    
    [self.selection removeIndex:0];
    
    return self.selection;
}

//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
//{
//    if (item == [self.projects objectAtIndex:0]) {
//        return NO;
//    }
//    
//    NSIndexSet *selectedIndexSet = [outlineView selectedRowIndexes];
//    if ([selectedIndexSet count] == 0) {
//        return YES;
//    }
//    
//    id selectedItem = [outlineView itemAtRow:[selectedIndexSet firstIndex]];
//    
//    if ([selectedItem class] != [item class])
//    {
//        return NO;
//    }
//    
//    return YES;
//}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if (item == [self.projects objectAtIndex:0]) {
        NSTextField *result = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        result.stringValue = @"PROJECTS";
        return result;
    }
    
    ProjectCellView *result = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
    result.backgroundStyle = NSBackgroundStyleDark;
    [((ProjectTextField*)result.textField) reloadItem:item];
    [((ProjectTextField*)result.textField) setPropertyKey:@"name"];
    [result.textField setSelectable:YES];
    [result.textField setEditable:YES];
    [result.numberBg setHidden:YES];
    [result.numberLabel setHidden:YES];
    result.data = item;
    
    result.normalBgImage = [NSImage imageNamed:@"stretchbg_count"];
    result.hightlightedBgImage = [NSImage imageNamed:@"stretchbg_count_highlighted"];
    
    [result.textField unbind:@"value"];
    [result.textField bind:@"value" toObject:item withKeyPath:@"name" options:[NSDictionary dictionary]];
    
    [result unbind:@"toolTip"];
    [result bind:@"toolTip" toObject:item withKeyPath:@"name" options:[NSDictionary dictionary]];
    
    [result.status setHidden:YES];
    
    if ([item isKindOfClass:[PAProject class]])
    {
        result.textField.stringValue = [(PAProject*)item name];
        result.normalImage = [NSImage imageNamed:@"icon_project"];
        result.highlightedImage = [NSImage imageNamed:@"icon_project_highlighted"];
    }
    else if ([item isKindOfClass:[PAApiFolder class]])
    {
        PAApiFolder *apis = (PAApiFolder*)item;
        result.textField.stringValue = @"Apis";
        result.normalImage = [NSImage imageNamed:@"icon_apifolder"];
        result.highlightedImage = [NSImage imageNamed:@"icon_apifolder_highlighted"];
        [result.textField setSelectable:NO];
        [result.numberBg setHidden:NO];
        [result.numberLabel setHidden:NO];
        [result.numberLabel setStringValue:[NSString stringWithFormat:@"%ld", apis.allChildren.count]];
    }
    else if ([item isKindOfClass:[PABeanFolder class]])
    {
        PABeanFolder *beans = (PABeanFolder*)item;
        result.textField.stringValue = @"Beans";
        result.normalImage = [NSImage imageNamed:@"icon_beanfolder"];
        result.highlightedImage = [NSImage imageNamed:@"icon_beanfolder_highlighted"];
        [result.textField setSelectable:NO];
        [result.numberBg setHidden:NO];
        [result.numberLabel setHidden:NO];
        [result.numberLabel setStringValue:[NSString stringWithFormat:@"%ld", beans.allChildren.count]];
    }
    else if ([item isKindOfClass:[PAApi class]])
    {
        PAApi *api = (PAApi*)item;
        result.textField.stringValue = api.name;
        result.normalImage = [NSImage imageNamed:@"icon_api"];
        result.highlightedImage = [NSImage imageNamed:@"icon_api_highlighted"];
        if (api.status == PAApiStatusRunning)
        {
            [result.status setHidden:NO];
            result.normalStatusImage = [NSImage imageNamed:@"icon_running"];
            result.highlightedStatusImage = [NSImage imageNamed:@"icon_running_highlighted"];
        }
        else if (api.status == PAApiStatusSuccess)
        {
            [result.status setHidden:NO];
            result.normalStatusImage = [NSImage imageNamed:@"icon_ok"];
            result.highlightedStatusImage = [NSImage imageNamed:@"icon_ok_highlighted"];
        }
        else if (api.status == PAApiStatusFailed)
        {
            [result.status setHidden:NO];
            result.normalStatusImage = [NSImage imageNamed:@"icon_fail"];
            result.highlightedStatusImage = [NSImage imageNamed:@"icon_fail_highlighted"];
        }
        else if (api.status == PAApiStatusNormal)
        {
            [result.status setHidden:YES];
            result.status.image = nil;
            result.normalStatusImage = nil;
            result.highlightedStatusImage = nil;
        }
    }
    else if ([item isKindOfClass:[PABean class]])
    {
        PABean *bean = (PABean*)item;
        result.textField.stringValue = bean.name;
        result.normalImage = [NSImage imageNamed:@"icon_bean"];
        result.highlightedImage = [NSImage imageNamed:@"icon_bean_highlighted"];
    }
    
//    result.toolTip = result.textField.stringValue;
    return result;
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
    //save expand states
    //    [api.expandedItems removeAllObjects];
    
    if (fromAutoExpand) {
        return ;
    }
    for (int i=1; i<self.projects.count;i++)
    {
        PAProject *pj = [self.projects objectAtIndex:i];
        if ([_projectPanel isItemExpanded:pj])
        {
            pj.expanded = YES;
            if ([_projectPanel isItemExpanded:pj.beans]) {
                pj.beans.expanded = YES;;
            }
            else
            {
                pj.beans.expanded = NO;
            }
            
            if ([_projectPanel isItemExpanded:pj.apis]) {
                pj.apis.expanded = YES;
            }
            else
            {
                pj.apis.expanded = NO;
            }
        }
        else
        {
            pj.expanded = NO;
            pj.beans.expanded = NO;
            pj.apis.expanded = NO;
        }
    }
    
//    for (int i=0; i<_projectPanel.numberOfRows; i++)
//    {
//        PAField *item = [_projectPanel itemAtRow:i];
//        NSString *si = [NSString stringWithFormat:@"%d", i];
//        if ([_projectPanel isItemExpanded:item])
//        {
//            BOOL exists = NO;
//            for (int j=0; j<gGlobalSetting.expandedItems.count; j++)
//            {
//                NSString *idx = [gGlobalSetting.expandedItems objectAtIndex:j];
//                if (si.integerValue == idx.integerValue)
//                {
//                    exists = YES;
//                    break;
//                }
//            }
//            
//            if (!exists) {
//                [gGlobalSetting.expandedItems addObject:si];
//            }
//        }
//    }
//    
//    [gGlobalSetting.expandedItems sortUsingSelector:@selector(compare:)];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
    //save expand states
    //    [api.expandedItems removeAllObjects];
    for (int i=1; i<self.projects.count;i++)
    {
        PAProject *pj = [self.projects objectAtIndex:i];
        if ([_projectPanel isItemExpanded:pj])
        {
            pj.expanded = YES;
            if ([_projectPanel isItemExpanded:pj.beans]) {
                pj.beans.expanded = YES;;
            }
            else
            {
                pj.beans.expanded = NO;
            }
            
            if ([_projectPanel isItemExpanded:pj.apis]) {
                pj.apis.expanded = YES;
            }
            else
            {
                pj.apis.expanded = NO;
            }
        }
        else
        {
            pj.expanded = NO;
            pj.beans.expanded = NO;
            pj.apis.expanded = NO;
        }
    }
    
//    [gGlobalSetting.expandedItems removeAllObjects];
//    for (int i=0; i<_projectPanel.numberOfRows; i++)
//    {
//        PAField *item = [_projectPanel itemAtRow:i];
//        NSString *si = [NSString stringWithFormat:@"%d", i];
//        if ([_projectPanel isItemExpanded:item])
//        {
//            BOOL exists = NO;
//            for (int j=0; j<gGlobalSetting.expandedItems.count; j++)
//            {
//                NSString *idx = [gGlobalSetting.expandedItems objectAtIndex:j];
//                if (si.integerValue == idx.integerValue)
//                {
//                    exists = YES;
//                    break;
//                }
//            }
//            
//            if (!exists) {
//                [gGlobalSetting.expandedItems addObject:si];
//            }
//        }
//    }
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
    ProjectTableRowView *row = [[ProjectTableRowView alloc] init];

    return [row autorelease];
}

- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{

}

//- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
//{
//    return item;
//}

#pragma mark -
#pragma mark ***** NSOutlineView Drag and Drop Support *****
/*
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[NSString class]];
    NSDictionary *options = [NSDictionary dictionary];
    NSString *srcString = nil;
    
    BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];
    if (ok) {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        if (objectsToPaste.count > 0)
        {
            srcString = [objectsToPaste objectAtIndex:0];
        }
        else
        {
            return NO;
        }
    }
    else
    {
        return NO;
    }
    
    
    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[NSString class]];
    NSDictionary *options = [NSDictionary dictionary];
    NSString *srcString = nil;
    
    BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];
    if (ok) {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        if (objectsToPaste.count > 0)
        {
            srcString = [objectsToPaste objectAtIndex:0];
        }
        else
        {
            return NSDragOperationNone;
        }
    }
    else
    {
        return NSDragOperationNone;
    }
    
    NSString *type = [PAExportEngine objectTypeForJsonString:srcString];
    if (!type && ![DTUtil isHttpURL:srcString])
    {
        return NSDragOperationNone;
    }
    
    if (!item) {
        return NSDragOperationGeneric;
    }
    else if ([item isKindOfClass:[PAProject class]])
    {
        if ([type isEqualToString:PAOBJECT_NAME_APIFOLDER] ||
            [type isEqualToString:PAOBJECT_NAME_BEANFOLDER] ||
            [type isEqualToString:PAOBJECT_NAME_BEAN_ARRAY] ||
            [type isEqualToString:PAOBJECT_NAME_NEW_BEAN_ARRAY] ||
            [type isEqualToString:PAOBJECT_NAME_BEAN] ||
            [type isEqualToString:PAOBJECT_NAME_API])
        {
            return NSDragOperationGeneric;
        }
    }
    else if ([item isKindOfClass:[PAApiFolder class]])
    {
        if ([type isEqualToString:PAOBJECT_NAME_API] ||
            [type isEqualToString:PAOBJECT_NAME_APIFOLDER] ||
            [type isEqualToString:PAOBJECT_NAME_API_ARRAY] || 
            [DTUtil isHttpURL:srcString])
        {
            return NSDragOperationGeneric;
        }
    }
    else if ([item isKindOfClass:[PABeanFolder class]])
    {
        if ([type isEqualToString:PAOBJECT_NAME_BEANFOLDER] ||
            [type isEqualToString:PAOBJECT_NAME_BEAN_ARRAY] ||
            [type isEqualToString:PAOBJECT_NAME_NEW_BEAN_ARRAY] ||
            [type isEqualToString:PAOBJECT_NAME_BEAN])
        {
            return NSDragOperationGeneric;
        }
    }
    
    
    return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
    NSMutableString *ms = [NSMutableString stringWithCapacity:1000];
    for (int i=0; i<items.count; i++)
    {
        id item = [items objectAtIndex:i];
        if ([item isKindOfClass:[PAObject class]])
        {
            if ([item isKindOfClass:[PAProject class]] ||
                [item isKindOfClass:[PABeanFolder class]] ||
                [item isKindOfClass:[PAApiFolder class]]) {
                return NO;
            }
            [ms setString:[(PAObject*)item dictString]];
        }
    }
    
    [pboard clearContents];
    NSArray *copiedObjects = [NSArray arrayWithObject:ms];
    [pboard writeObjects:copiedObjects];
//    NSLog(@"drag:%@", ms);
    return YES;
}
*/
#pragma mark -
#pragma mark ***** Menu Delegate *****

- (void)menuWillOpen:(NSMenu *)menu
{
    NSInteger clickedRow = [_projectPanel clickedRow];
    NSIndexSet *indexSet = [_projectPanel selectedRowIndexes];
    if (![indexSet containsIndex:clickedRow]) {
//        [_projectPanel selectRowIndexes:[NSIndexSet indexSetWithIndex:clickedRow] byExtendingSelection:NO];
    }
    
    id item = [_projectPanel itemAtRow:clickedRow];
    if (!item) {
        [self reloadMenuItems:PROJECT_MENU_ROOT];
    }
    else
    {
        [_projectPanel expandItem:item];
        if ([item isKindOfClass:[PAProject class]])
        {
            [self reloadMenuItems:PROJECT_MENU_PROJECT];
        }
        else if ([item isKindOfClass:[PAApiFolder class]])
        {
            [self reloadMenuItems:PROJECT_MENU_APIFOLDER];
        }
        else if ([item isKindOfClass:[PABeanFolder class]])
        {
            [self reloadMenuItems:PROJECT_MENU_BEANFOLDER];
        }
        else if ([item isKindOfClass:[PAApi class]])
        {
            [self reloadMenuItems:PROJECT_MENU_API];
        }
        else if ([item isKindOfClass:[PABean class]])
        {
            [self reloadMenuItems:PROJECT_MENU_BEAN];
        }
    }
}

#pragma mark -
#pragma mark ***** Actions *****
-(void)reloadMenuItems:(ProjectMenuType)menuType
{
    _menuType = menuType;
    [projectMenu removeAllItems];
    NSMenuItem *item = nil;
    
    switch (_menuType) {
        case PROJECT_MENU_ROOT:
        {
            item = [[[NSMenuItem alloc] initWithTitle:@"Add Project" action:@selector(addProjectFromMenu) keyEquivalent:@""] autorelease];
            [item setTarget:self];
            [projectMenu addItem:item];
            
        }
            break;
        case PROJECT_MENU_PROJECT:
        {
            item = [[[NSMenuItem alloc] initWithTitle:@"Add Project" action:@selector(addProjectFromMenu) keyEquivalent:@""] autorelease];
            [item setTarget:self];
            [projectMenu addItem:item];
            item = [[[NSMenuItem alloc] initWithTitle:@"Add Api" action:@selector(addApiFromMenu) keyEquivalent:@""] autorelease];
            [item setTarget:self];
            [projectMenu addItem:item];
            item = [[[NSMenuItem alloc] initWithTitle:@"Add Bean" action:@selector(addBeanFromMenu) keyEquivalent:@""] autorelease];
            [item setTarget:self];
            [projectMenu addItem:item];
//            item = [NSMenuItem separatorItem];
//            [projectMenu addItem:item];
//            item = [[[NSMenuItem alloc] initWithTitle:@"Export Project" action:@selector(exportFromMenu) keyEquivalent:@""] autorelease];
//            [item setTarget:self];
//            [projectMenu addItem:item];
        }
            break;
        case PROJECT_MENU_APIFOLDER:
        {
            item = [[[NSMenuItem alloc] initWithTitle:@"Add Api" action:@selector(addApiFromMenu) keyEquivalent:@""] autorelease];
            [item setTarget:self];
            [projectMenu addItem:item];
//            item = [[[NSMenuItem alloc] initWithTitle:@"Export All Apis" action:@selector(exportFromMenu) keyEquivalent:@""] autorelease];
//            [item setTarget:self];
//            [projectMenu addItem:item];
        }
            break;
        case PROJECT_MENU_API:
        {
            item = [[[NSMenuItem alloc] initWithTitle:@"Add Api" action:@selector(addApiFromMenu) keyEquivalent:@""] autorelease];
            [item setTarget:self];
            [projectMenu addItem:item];
//            item = [NSMenuItem separatorItem];
//            [projectMenu addItem:item];
//            item = [[[NSMenuItem alloc] initWithTitle:@"Export Api" action:@selector(exportFromMenu) keyEquivalent:@""] autorelease];
//            [item setTarget:self];
//            [projectMenu addItem:item];
        }
            break;
        case PROJECT_MENU_BEANFOLDER:
        {
            item = [[[NSMenuItem alloc] initWithTitle:@"Add Bean" action:@selector(addBeanFromMenu) keyEquivalent:@""] autorelease];
            [item setTarget:self];
            [projectMenu addItem:item];
//            item = [[[NSMenuItem alloc] initWithTitle:@"Export All Beans" action:@selector(exportFromMenu) keyEquivalent:@""] autorelease];
//            [item setTarget:self];
//            [projectMenu addItem:item];
        }
            break;
        case PROJECT_MENU_BEAN:
        {
            item = [[[NSMenuItem alloc] initWithTitle:@"Add Bean" action:@selector(addBeanFromMenu) keyEquivalent:@""] autorelease];
            [item setTarget:self];
            [projectMenu addItem:item];
//            item = [NSMenuItem separatorItem];
//            [projectMenu addItem:item];
//            item = [[[NSMenuItem alloc] initWithTitle:@"Export Bean" action:@selector(exportFromMenu) keyEquivalent:@""] autorelease];
//            [item setTarget:self];
//            [projectMenu addItem:item];
        }
            break;
        default:
            break;
    }
    
    switch (_menuType) {
        case PROJECT_MENU_PROJECT:
        case PROJECT_MENU_API:
        case PROJECT_MENU_BEAN:
        {
            NSString *removeString = nil;
            if (_menuType == PROJECT_MENU_PROJECT) removeString = @"Remove Project";
            else if (_menuType == PROJECT_MENU_API) removeString = @"Remove Api";
            else if (_menuType == PROJECT_MENU_BEAN) removeString = @"Remove Bean";
            
            item = [NSMenuItem separatorItem];
            [projectMenu addItem:item];
            item = [[[NSMenuItem alloc] initWithTitle:removeString action:@selector(removeFromMenu) keyEquivalent:@""] autorelease];
            [item setTarget:self];
            [projectMenu addItem:item];
        }
            break;
            
        default:
            break;
    }
}

-(void)exportBeanAction
{
//    NSInteger selectedRow = [_projectPanel selectedRow];
    NSIndexSet *selectedRows = [_projectPanel selectedRowIndexes];
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
    __block PAProject *project = nil;
    
    [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        id item = [_projectPanel itemAtRow:idx];
        if ([item isKindOfClass:[PABean class]])
        {
            project = [item project];
            [ma addObject:item];
        }
    }];
    
    
    if (ma.count > 0)
    {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        openPanel.canChooseDirectories = YES;
        openPanel.canChooseFiles = NO;
        openPanel.allowsMultipleSelection = NO;
        NSUInteger result = [openPanel runModal];
        if (result == NSFileHandlingPanelOKButton)
        {
            [PAExportEngine exportBeans:ma inProject:project toFolderPath:openPanel.URL.path withTemplate:kPATemplateBeanIOS];
        }
    }
}

-(void)exportAllBeansAction
{
    NSInteger selectedRow = [_projectPanel selectedRow];
    
    id item = [_projectPanel itemAtRow:selectedRow];
    PAProject *project = nil;
    
    NSArray *allBeans = nil;
    
    if ([item isKindOfClass:[PAProject class]])
    {
        project = item;
        allBeans = project.beans.allChildren;
    }
    else
    {
        project = [item project];
        allBeans = project.beans.allChildren;
    }
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    openPanel.allowsMultipleSelection = NO;
    NSUInteger result = [openPanel runModal];
    if (result == NSFileHandlingPanelOKButton)
    {
        [PAExportEngine exportBeans:allBeans inProject:[item project] toFolderPath:openPanel.URL.path withTemplate:kPATemplateBeanIOS];
    }
}

#pragma mark -
#pragma mark ***** Menu Actions *****
-(void)addProjectFromMenu
{
    isAdding = YES;
    PAProject *pap = [[[PAProject alloc] init] autorelease];
    pap.expanded = YES;
    pap.name = [self newProjectNameByName:@"NewProject"];
    pap.allProjectsRefs = self.allProjects;
    pap.rowIndex = self.allProjects.count;
    [self insertProjects:[NSArray arrayWithObject:pap]];
}

-(void)addApiFromMenu
{
    id item = [_projectPanel itemAtRow:[_projectPanel clickedRow]];
    PAApiFolder *parent = nil;
    
    if ([item isKindOfClass:[PAApi class]])
    {
        parent = [_projectPanel parentForItem:item];
    }
    else if ([item isKindOfClass:[PAApiFolder class]])
    {
        parent = (PAApiFolder*)item;
    }
    else if ([item isKindOfClass:[PAProject class]])
    {
        parent = [(PAProject*)item apis];
    }
    
    PAProject *project = [_projectPanel parentForItem:parent];
    [_projectPanel expandItem:project];
    
    PAApi *api = [parent defaultApi];
    api.rowIndex = parent.allChildren.count;
    api.project = project;
    
    isAdding = YES;
    [project insertApis:[NSArray arrayWithObject:api]];

}

-(void)addBeanFromMenu
{
    id item = [_projectPanel itemAtRow:[_projectPanel clickedRow]];
    PABeanFolder *parent = nil;
    
    if ([item isKindOfClass:[PABean class]])
    {
        parent = [_projectPanel parentForItem:item];
    }
    else if ([item isKindOfClass:[PABeanFolder class]])
    {
        parent = (PABeanFolder*)item;
    }
    else if ([item isKindOfClass:[PAProject class]])
    {
        parent = [(PAProject*)item beans];
    }
    
    PAProject *project = [_projectPanel parentForItem:parent];
    [_projectPanel expandItem:project];
    
    PABean *bean = [parent defaultBean];
    bean.rowIndex = parent.allChildren.count;
    bean.project = project;
    
    isAdding = YES;
    [project insertBeans:[NSArray arrayWithObject:bean]];
}

-(void)addApiFromTopMenu
{
    id item = [_projectPanel itemAtRow:[_projectPanel selectedRow]];
    PAApiFolder *parent = nil;
    
    if ([item isKindOfClass:[PAApi class]])
    {
        parent = [_projectPanel parentForItem:item];
    }
    else if ([item isKindOfClass:[PAApiFolder class]])
    {
        parent = (PAApiFolder*)item;
    }
    else if ([item isKindOfClass:[PAProject class]])
    {
        parent = [(PAProject*)item apis];
    }
    
    PAProject *project = [_projectPanel parentForItem:parent];
    [_projectPanel expandItem:project];
    
    PAApi *api = [parent defaultApi];
    api.rowIndex = parent.allChildren.count;
    api.project = project;
    
    isAdding = YES;
    [project insertApis:[NSArray arrayWithObject:api]];
    
}

-(void)addBeanFromTopMenu
{
    id item = [_projectPanel itemAtRow:[_projectPanel selectedRow]];
    PABeanFolder *parent = nil;
    
    if ([item isKindOfClass:[PABean class]])
    {
        parent = [_projectPanel parentForItem:item];
    }
    else if ([item isKindOfClass:[PABeanFolder class]])
    {
        parent = (PABeanFolder*)item;
    }
    else if ([item isKindOfClass:[PAProject class]])
    {
        parent = [(PAProject*)item beans];
    }
    
    PAProject *project = [_projectPanel parentForItem:parent];
    [_projectPanel expandItem:project];
    
    PABean *bean = [parent defaultBean];
    bean.rowIndex = parent.allChildren.count;
    bean.project = project;
    
    isAdding = YES;
    [project insertBeans:[NSArray arrayWithObject:bean]];
}

-(BOOL)projectMenuValidate:(NSUInteger)tag
{
    if (tag == 50001)
    {
        return YES;
    }
    else if (tag == 50002)
    {
        id item = [_projectPanel itemAtRow:[_projectPanel selectedRow]];
        if ([item isKindOfClass:[PAProject class]] ||
            [item isKindOfClass:[PAApiFolder class]] ||
            [item isKindOfClass:[PAApi class]])
        {
            return YES;
        }
    }
    else if (tag == 50003)
    {
        id item = [_projectPanel itemAtRow:[_projectPanel selectedRow]];
        if ([item isKindOfClass:[PAProject class]] ||
            [item isKindOfClass:[PABeanFolder class]] ||
            [item isKindOfClass:[PABean class]])
        {
            return YES;
        }
    }
    
    return NO;
}

-(void)removeFromMenu
{
    NSIndexSet *indexSet = [_projectPanel selectedRowIndexes];
    NSInteger clickedRow = [_projectPanel clickedRow];
    
    __block NSMutableArray *items = [NSMutableArray arrayWithCapacity:5];
    __block BOOL isClickIn = NO;
    
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [items addObject:[_projectPanel itemAtRow:idx]];
        if (idx == clickedRow) {
            isClickIn = YES;
        }
    }];
    
    if (!isClickIn) {
        [items removeAllObjects];
        [items addObject:[_projectPanel itemAtRow:clickedRow]];
    }

    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure to delete the item?" defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@""];
    NSInteger result = [alert runModal];
    
    
    if (items.count>0 && result == NSAlertDefaultReturn)
    {
        [self.selection removeIndexes:[_projectPanel selectedRowIndexes]];
        
        id item = [items objectAtIndex:0];
        if ([item isKindOfClass:[PAProject class]])
        {
            [self removeProjects:items];
        }
        else if ([item isKindOfClass:[PAApi class]])
        {
            PAApiFolder *parent = [_projectPanel parentForItem:item];
            PAProject *project = [_projectPanel parentForItem:parent];
            
            [project removeApis:items];
        }
        else if ([item isKindOfClass:[PABean class]])
        {
            PABeanFolder *parent = [_projectPanel parentForItem:item];
            PAProject *project = [_projectPanel parentForItem:parent];
            isRemoving = YES;
            [project removeBeans:items];
        }
    }
}

-(void)exportFromMenu
{
    
}

#pragma mark -
#pragma mark ***** Notifications *****

-(void)selectionChanged:(id)sender
{
    NSInteger selectedRow = [_projectPanel selectedRow];
    if (selectedRow == -1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECTPANEL_CHANGED object:nil];
        return ;
    }
    
    id item = [_projectPanel itemAtRow:selectedRow];
    
    NSIndexSet *indexes = [_projectPanel selectedRowIndexes];
    [selection removeAllIndexes];
    [selection addIndexes:indexes];
    
    if ([item isKindOfClass:[PAProject class]] ||
        [item isKindOfClass:[PAApi class]] ||
        [item isKindOfClass:[PABean class]])
    {
        [addBtn setEnabled:YES];
        [removeBtn setEnabled:YES];
    }
    else if ([item isKindOfClass:[PAApiFolder class]] ||
             [item isKindOfClass:[PABeanFolder class]])
    {
        [addBtn setEnabled:YES];
        [removeBtn setEnabled:NO];
    }
    else
    {
        [addBtn setEnabled:NO];
        [removeBtn setEnabled:NO];
    }
    
    if ([item isKindOfClass:[PAApi class]])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_APISELECTION_CHANGED object:item];
    }
    
    
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
    [selection enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [ma addObject:[_projectPanel itemAtRow:idx]];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECTPANEL_CHANGED object:ma];
}

-(void)controlTextChanged:(NSNotification*)notification
{
    if (_searchField == notification.object) {
        [self filterOutlineView];
    } ;
}

-(void)cellTextFieldDidChanged:(NSNotification*)notification
{
    id item = notification.object;
    id parent = [_projectPanel parentForItem:item];
    [_projectPanel reloadItem:parent reloadChildren:YES];
}

-(void)filterOutlineView
{
    NSString *keyword = [_searchField.stringValue lowercaseString];
    
    @synchronized(self.projects)
    {
        [self.projects removeAllObjects];
        [self.projects addObject:@"Projects"];
        
        for (int i=1; i<self.allProjects.count; i++)
        {
            PAProject *pap = [self.allProjects objectAtIndex:i];
            [pap.apis filterChildren:keyword];
            [pap.beans filterChildren:keyword];
            if (keyword.length == 0 ||
                [[pap.name lowercaseString] rangeOfString:keyword].length > 0 ||
                pap.apis.children.count > 0 ||
                pap.beans.children.count > 0)
            {
                [self.projects addObject:pap];
            }
        }
        
        [_projectPanel reloadItem:nil reloadChildren:YES];
        [_projectPanel expandItem:nil expandChildren:YES];
    }
}

-(void)projectBeansChanged:(NSNotification*)notification
{
    NSDictionary *dict = notification.object;
    PAProject *project = [dict objectForKey:@"object"];
    NSString *operation = [dict objectForKey:@"operation"];
    NSArray *array = [dict objectForKey:@"beans"];
    NSIndexSet *indexSet = [dict objectForKey:@"indexSet"];
    
    if ([operation isEqualToString:@"insert"])
    {
        [_projectPanel reloadItem:project.beans reloadChildren:YES];
        if (isAdding && array.count > 0)
        {
            [_projectPanel expandItem:project.beans];
            NSInteger editRow = [_projectPanel rowForItem:[array objectAtIndex:0]];
            if (editRow != -1) {
                [_projectPanel selectRowIndexes:[NSIndexSet indexSetWithIndex:editRow] byExtendingSelection:NO];
                [_projectPanel editColumn:0 row:editRow withEvent:nil select:YES];
                [_projectPanel scrollRowToVisible:editRow];
            }
        }
        else if (!isAdding)
        {
//            NSMutableIndexSet *mindexSet = [NSMutableIndexSet indexSet];
//            for (int i=0; i<array.count; i++) {
//                NSInteger ridx = [_projectPanel rowForItem:[array objectAtIndex:i]];
//                [mindexSet addIndex:ridx];
//            }
//            [_projectPanel selectRowIndexes:mindexSet byExtendingSelection:NO];
        }
        isAdding = NO;
    }
    else if ([operation isEqualToString:@"remove"])
    {
        [_projectPanel reloadItem:project.beans reloadChildren:YES];
        if (project.beans.allChildren.count > 1)
        {
            NSUInteger last_index = [indexSet lastIndex];
            NSUInteger itemRow = 0;
            
            BOOL exists = NO;
            for (NSUInteger i=0; i<project.beans.allChildren.count; i++)
            {
                PAApi *p = [project.beans.allChildren objectAtIndex:i];
                if (p.rowIndex >= 0 && p.rowIndex > last_index)
                {
                    itemRow = [_projectPanel rowForItem:p];
                    exists = YES;
                    break;
                }
            }
            
            if (!exists) {
                PABean *p = [project.beans.allChildren lastObject];
                itemRow = [_projectPanel rowForItem:p];
            }
            
            if (isRemoving) [_projectPanel selectRowIndexes:[NSIndexSet indexSetWithIndex:itemRow] byExtendingSelection:NO];
        }
        isRemoving = NO;
    }
    
//    [gWindowController disableMappingMenus];
}

-(void)projectApisChanged:(NSNotification*)notification
{
    NSDictionary *dict = notification.object;
    PAProject *project = [dict objectForKey:@"object"];
    NSString *operation = [dict objectForKey:@"operation"];
    NSArray *array = [dict objectForKey:@"apis"];
    NSIndexSet *indexSet = [dict objectForKey:@"indexSet"];
    
    if ([operation isEqualToString:@"insert"])
    {
        [_projectPanel reloadItem:project reloadChildren:YES];
        if (isAdding && array.count > 0)
        {
            [_projectPanel expandItem:project.apis];
            NSInteger editRow = [_projectPanel rowForItem:[array objectAtIndex:0]];
            if (editRow != -1) {
                [_projectPanel selectRowIndexes:[NSIndexSet indexSetWithIndex:editRow] byExtendingSelection:NO];
                [_projectPanel editColumn:0 row:editRow withEvent:nil select:YES];
                [_projectPanel scrollRowToVisible:editRow];
            }
        }
        else if (!isAdding)
        {
            NSMutableIndexSet *mindexSet = [NSMutableIndexSet indexSet];
            for (int i=0; i<array.count; i++) {
                [mindexSet addIndex:[_projectPanel rowForItem:[array objectAtIndex:i]]];
            }
            [_projectPanel selectRowIndexes:mindexSet byExtendingSelection:NO];
        }
    }
    else if ([operation isEqualToString:@"remove"])
    {
        [_projectPanel reloadItem:project reloadChildren:YES];
        if (project.apis.allChildren.count > 1)
        {
            NSUInteger last_index = [indexSet lastIndex];
            NSUInteger itemRow = 0;
            
            BOOL exists = NO;
            for (NSUInteger i=0; i<project.apis.allChildren.count; i++)
            {
                PAApi *p = [project.apis.allChildren objectAtIndex:i];
                if (p.rowIndex >= 0 && p.rowIndex > last_index)
                {
                    itemRow = [_projectPanel rowForItem:p];
                    exists = YES;
                    break;
                }
            }
            
            if (!exists) {
                PAApi *p = [project.apis.allChildren lastObject];
                itemRow = [_projectPanel rowForItem:p];
            }
            
            [_projectPanel selectRowIndexes:[NSIndexSet indexSetWithIndex:itemRow] byExtendingSelection:NO];
        }
    }
    
    isAdding = NO;
}

-(void)apiChildrenChanged:(NSNotification*)notification
{
    NSDictionary *dict = notification.object;
    PAApi *api = [dict objectForKey:@"object"];
    NSString *oper = [dict objectForKey:@"operation"];
    if ([oper isEqualToString:@"insert"] ||
        [oper isEqualToString:@"remove"]) {
        NSInteger row = [_projectPanel rowForItem:api];
        NSInteger selectedRow = [_projectPanel selectedRow];
        if (row != selectedRow) {
            [_projectPanel selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        }
    }
}

-(void)beanChildrenChanged:(NSNotification*)notification
{
    NSInteger selectedRow = [_projectPanel selectedRow];
    id item = [_projectPanel itemAtRow:selectedRow];
    
    if (!item) {
        return ;
    }
    
    if ([item isKindOfClass:[PAApi class]]) {
        return ;
    }
    
    NSDictionary *dict = notification.object;
    PABean *bean = [dict objectForKey:@"object"];
    NSString *oper = [dict objectForKey:@"operation"];
    if ([oper isEqualToString:@"insert"] ||
        [oper isEqualToString:@"remove"]) {
        NSInteger row = [_projectPanel rowForItem:bean];
        NSInteger selectedRow = [_projectPanel selectedRow];
        if (row != selectedRow) {
            [_projectPanel selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        }
    }
}

-(void)apiStatusChanged:(NSNotification*)notification
{
    id api = notification.object;
    NSInteger aidx = [_projectPanel rowForItem:api];
    [_projectPanel reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:aidx] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

-(void)projectChildrenChanged:(NSNotification*)notification
{
//    PAProject *project = notification.object;
//    [_projectPanel reloadItem:project.beans reloadChildren:YES];
//    [_projectPanel reloadItem:project.apis reloadChildren:YES];
}

-(void)projectsChanged:(NSNotification*)notification
{
    NSDictionary *dict = notification.object;
    NSArray *array = [dict objectForKey:@"array"];
    NSString *operation = [dict objectForKey:@"operation"];
    NSIndexSet *indexSet = [dict objectForKey:@"indexSet"];
    
    if ([operation isEqualToString:@"insert"])
    {
        if (_searchField.stringValue.length > 0) {
            [self filterOutlineView];
        }
        else
        {
            [_projectPanel reloadItem:nil reloadChildren:YES];
            NSArray *cprojects = [self.allProjects objectsAtIndexes:indexSet];
            NSMutableIndexSet *mindexSet = [NSMutableIndexSet indexSet];
            for (PAProject *p in cprojects) {
                [mindexSet addIndex:[_projectPanel rowForItem:p]];
            }
            
//            [_projectPanel selectRowIndexes:mindexSet byExtendingSelection:NO];
            if (isAdding)
            {
                isAdding = NO;
                NSArray *tmp = [self.allProjects objectsAtIndexes:indexSet];
                PAProject *pj = nil;
                if (tmp.count > 0) {
                    pj = [tmp objectAtIndex:0];
                }
                NSInteger editRow = [_projectPanel rowForItem:pj];
                if (editRow != -1)
                {
                    [_projectPanel expandItem:pj];
                    [_projectPanel selectRowIndexes:[NSIndexSet indexSetWithIndex:editRow] byExtendingSelection:NO];
                    [_projectPanel scrollRowToVisible:editRow+2];
                    [_projectPanel editColumn:0 row:editRow withEvent:nil select:YES];
                }
            }
            else if (!isAdding)
            {
                NSMutableIndexSet *mindexSet = [NSMutableIndexSet indexSet];
                for (int i=0; i<array.count; i++) {
                    [mindexSet addIndex:[_projectPanel rowForItem:[array objectAtIndex:i]]];
                }
                [_projectPanel selectRowIndexes:mindexSet byExtendingSelection:NO];
            }
        }
    }
    else if ([operation isEqualToString:@"remove"])
    {
        if (_searchField.stringValue.length > 0) {
            [self filterOutlineView];
        }
        else
        {
            [_projectPanel reloadItem:nil reloadChildren:YES];
            if (self.allProjects.count > 1)
            {
                NSUInteger last_index = [indexSet lastIndex];
                NSUInteger itemRow = 0;
                
                BOOL exists = NO;
                for (NSUInteger i=1; i<self.allProjects.count; i++)
                {
                    PAProject *p = [self.allProjects objectAtIndex:i];
                    if (p.rowIndex >= 0 && p.rowIndex > last_index)
                    {
                        itemRow = [_projectPanel rowForItem:p];
                        exists = YES;
                        break;
                    }
                }
                
                if (!exists) {
                    PAProject *p = [self.allProjects lastObject];
                    itemRow = [_projectPanel rowForItem:p];
                }
                
                [_projectPanel selectRowIndexes:[NSIndexSet indexSetWithIndex:itemRow] byExtendingSelection:NO];
            }
        }
    }
}

#pragma mark -
#pragma mark ***** ProjectOutlineViewDelegate *****

-(void)outlineView:(ProjectOutlineView*)outlineView pasteItem:(id)pastitem
{
    [self addObjectsFromJsonString:pastitem];
}

-(void)outlineView:(ProjectOutlineView*)outlineView cutItem:(id)item
{
    NSIndexSet *indexSet = [_projectPanel selectedRowIndexes];
    
    __block NSMutableArray *items = [NSMutableArray arrayWithCapacity:5];
    
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [items addObject:[_projectPanel itemAtRow:idx]];
    }];

    if (items.count>0)
    {
        [self.selection removeIndexes:[_projectPanel selectedRowIndexes]];
        
        id item = [items objectAtIndex:0];
        if ([item isKindOfClass:[PAProject class]])
        {
            [self removeProjects:items];
        }
        else if ([item isKindOfClass:[PAApi class]])
        {
            PAApiFolder *parent = [_projectPanel parentForItem:item];
            PAProject *project = [_projectPanel parentForItem:parent];
            
            [project removeApis:items];
        }
        else if ([item isKindOfClass:[PABean class]])
        {
            PABeanFolder *parent = [_projectPanel parentForItem:item];
            PAProject *project = [_projectPanel parentForItem:parent];
            
            [project removeBeans:items];
        }
    }
}

-(void)outlineView:(ProjectOutlineView*)outlineView deleteItem:(id)item
{
    NSIndexSet *indexSet = [_projectPanel selectedRowIndexes];
    
    __block NSMutableArray *items = [NSMutableArray arrayWithCapacity:5];
    
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [items addObject:[_projectPanel itemAtRow:idx]];
    }];

    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure to delete the item?" defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@""];
    NSInteger result = [alert runModal];
    
    
    if (items.count>0 && result == NSAlertDefaultReturn)
    {
        [self.selection removeIndexes:[_projectPanel selectedRowIndexes]];
        
        id item = [items objectAtIndex:0];
        if ([item isKindOfClass:[PAProject class]])
        {
            [self removeProjects:items];
        }
        else if ([item isKindOfClass:[PAApi class]])
        {
            PAApiFolder *parent = [_projectPanel parentForItem:item];
            PAProject *project = [_projectPanel parentForItem:parent];
            
            [project removeApis:items];
        }
        else if ([item isKindOfClass:[PABean class]])
        {
            PABeanFolder *parent = [_projectPanel parentForItem:item];
            PAProject *project = [_projectPanel parentForItem:parent];
            
            [project removeBeans:items];
        }
    }
}

-(void)addObjectsFromJsonString:(NSString*)jsonString
{
    NSString *type = [PAExportEngine objectTypeForJsonString:jsonString];
    NSArray *objs = [PAExportEngine arrayForJsonString:jsonString type:type];
    if (objs && objs.count != 0)
    {
        if ([type isEqualToString:PAOBJECT_NAME_PROJECT_ARRAY] ||
            [type isEqualToString:PAOBJECT_NAME_PROJECT])
        {
            for (int i=0; i<objs.count; i++)
            {
                PAProject *p = [objs objectAtIndex:i];
                p.name = [self newProjectNameByName:p.name];
                p.rowIndex = self.allProjects.count + i;
            }
            [self insertProjects:objs];
        }
        else if ([type isEqualToString:PAOBJECT_NAME_BEAN_ARRAY] ||
                 [type isEqualToString:PAOBJECT_NAME_BEAN] ||
                 [type isEqualToString:PAOBJECT_NAME_BEANFOLDER_ARRAY] ||
                 [type isEqualToString:PAOBJECT_NAME_BEANFOLDER])
        {
            id item = [_projectPanel itemAtRow:[_projectPanel selectedRow]];
            PAProject *pj = nil;
            
            if ([item isKindOfClass:[PAProject class]])
            {
                pj = item;
            }
            else if ([item isKindOfClass:[PABean class]] ||
                     [item isKindOfClass:[PABeanFolder class]])
            {
                pj = [item project];
            }
            
            if (pj) {
                for (int i=0; i<objs.count; i++) {
                    PABean *b = [objs objectAtIndex:i];
                    b.name = [pj bean:b valueByValue:b.name forKey:@"name"];
                    b.beanName = [pj bean:b valueByValue:b.beanName forKey:@"beanName"];
                    b.project = pj;
                    b.rowIndex = pj.beans.allChildren.count + i;
                }
                [pj insertBeans:objs];
            }
        }
        else if ([type isEqualToString:PAOBJECT_NAME_API_ARRAY] ||
                 [type isEqualToString:PAOBJECT_NAME_API] ||
                 [type isEqualToString:PAOBJECT_NAME_APIFOLDER_ARRAY] ||
                 [type isEqualToString:PAOBJECT_NAME_APIFOLDER])
        {
            id item = [_projectPanel itemAtRow:[_projectPanel selectedRow]];
            PAProject *pj = nil;
            
            if ([item isKindOfClass:[PAProject class]])
            {
                pj = item;
            }
            else if ([item isKindOfClass:[PAApi class]] ||
                     [item isKindOfClass:[PAApiFolder class]])
            {
                pj = [item project];
            }
            
            if (pj) {
                for (int i=0; i<objs.count; i++)
                {
                    PAApi *a = [objs objectAtIndex:i];
                    a.name = [pj api:a valueByValue:a.name forKey:@"name"];
                    a.project = pj;
                    a.rowIndex = pj.apis.allChildren.count + i;
                }
                [pj insertApis:objs];
            }
        }
    }
    else if ([type isEqualToString:PAOBJECT_NAME_NEW_BEAN_ARRAY] ||
             [type isEqualToString:PAOBJECT_NAME_NEW_BEAN])
    {
        id item = [_projectPanel itemAtRow:[_projectPanel selectedRow]];
        PAProject *pj = nil;
        
        if ([item isKindOfClass:[PAProject class]])
        {
            pj = item;
        }
        else if ([item isKindOfClass:[PABean class]] ||
                 [item isKindOfClass:[PABeanFolder class]])
        {
            pj = [item project];
        }
        
        if (pj) {
            NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
            [PAMappingEngine createBeanForDictionary:[jsonString JSONValue] withKey:nil inProject:pj toTmpArray:ma];
            for (int i=0; i<ma.count; i++)
            {
                PABean *b = [ma objectAtIndex:i];
                b.name = [pj bean:b valueByValue:b.name forKey:@"name"];
                b.beanName = [pj bean:b valueByValue:b.beanName forKey:@"beanName"];
                b.project = pj;
                b.rowIndex = pj.beans.allChildren.count + i;
            }
            [pj insertBeans:ma];
        }
    }
    else if ([type isEqualToString:PAOBJECT_NAME_NEW_API])
    {
        id item = [_projectPanel itemAtRow:[_projectPanel selectedRow]];
        PAProject *pj = nil;
        
        if ([item isKindOfClass:[PAProject class]])
        {
            pj = item;
        }
        else if ([item isKindOfClass:[PAApi class]] ||
                 [item isKindOfClass:[PAApiFolder class]])
        {
            pj = [item project];
        }
        
        if (pj)
        {
            PAApi *newApi = [pj.apis defaultApi];
            newApi.project = pj;
            NSArray *tmp = [jsonString componentsSeparatedByString:@"?"];
            if (tmp.count > 0)
            {
                NSString *prefix = [tmp objectAtIndex:0];
                if (![pj.baseUrl isEqualToString:prefix])
                {
                    newApi.url = prefix;
                }
            }
            
            NSDictionary *params = [PAParam parseUrlString:jsonString];
            NSArray *keys = [params allKeys];
            for (int i=0; i<keys.count; i++)
            {
                NSString *k = [keys objectAtIndex:i];
                NSString *v = [params objectForKey:k];
                PAParam *p = [newApi.selectedParamGroup defaultGetParam];
                p.name = [newApi.selectedParamGroup newParamValueByValue:k forKey:@"name" isPost:NO];
                p.paramKey = [newApi.selectedParamGroup newParamValueByValue:k forKey:@"paramKey" isPost:NO];
                p.parentGroup = newApi.selectedParamGroup;
                p.paramValue = v;
                [newApi.selectedParamGroup.getParams addObject:p];
            }
            
            [pj insertApis:[NSArray arrayWithObject:newApi]];
        }
    }
}

#pragma mark -
#pragma mark ***** PAProject  *****
-(NSString*)newProjectNameByName:(NSString*)pname
{
    NSMutableString *ms = [NSMutableString stringWithString:pname];
    int i=1;
    while ([self projectNameExists:ms])
    {
        [ms setString:[NSString stringWithFormat:@"%@_%d", pname, i]];
        i++;
    }
    return ms;
}

-(BOOL)projectNameExists:(NSString*)pname
{
    for (int i=1; i<self.allProjects.count; i++)
    {
        PAProject *project = [self.allProjects objectAtIndex:i];
        
        if ([project.name isEqualToString:pname])
        {
            return YES;
        }
    }
    return NO;
}

-(void)insertProjects:(NSArray *)array
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:10];
    [tmp setArray:self.allProjects];
    [tmp removeObjectAtIndex:0];
    
    for (int i=0; i<array.count; i++)
    {
        PAProject *p = [array objectAtIndex:i];
        if (p.rowIndex > tmp.count) {
            [indexSet addIndex:tmp.count+1];
        }
        else
        {
            [indexSet addIndex:p.rowIndex];
        }
        p.name = [PAObject object:p valueByValue:p.name forKey:@"name" existsObjects:tmp];
        [tmp addObject:p];
    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeProjects:array];
    
    [self.allProjects insertObjects:array atIndexes:indexSet];
    if (_searchField.stringValue.length == 0) {
        [self.projects insertObjects:array atIndexes:indexSet];
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.allProjects, @"object",
                          array, @"array",
                          @"insert", @"operation",
                          indexSet, @"indexSet", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECTROOT_CHANGED object:dict];
}

-(void)removeProjects:(NSArray *)array
{
    NSIndexSet *indexSet = [PAObject indexesForObjects:array inArray:self.allProjects];

    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] insertProjects:array];
    
    [self.allProjects removeObjectsAtIndexes:indexSet];
    if (_searchField.stringValue.length == 0) {
        [self.projects removeObjectsAtIndexes:indexSet];
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.allProjects, @"object",
                          array, @"array",
                          @"remove", @"operation",
                          indexSet, @"indexSet", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECTROOT_CHANGED object:dict];
}

-(void)modifyProjects:(NSArray*)array isInsert:(BOOL)isInsert
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    if (isInsert)
    {
        NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:10];
        [tmp setArray:self.allProjects];
        [tmp removeObjectAtIndex:0];
        
        for (int i=0; i<array.count; i++)
        {
            PAProject *p = [array objectAtIndex:i];
            if (p.rowIndex > tmp.count) {
                [indexSet addIndex:tmp.count+1];
            }
            else
            {
                [indexSet addIndex:p.rowIndex];
            }
            p.name = [PAObject object:p valueByValue:p.name forKey:@"name" existsObjects:tmp];
            [tmp addObject:p];
        }
    }
    else
    {
        NSIndexSet *tmp = [PAObject indexesForObjects:array inArray:self.allProjects];
        [indexSet addIndexes:tmp];
    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] modifyProjects:array isInsert:!isInsert];
    if (isInsert) {
        [self.allProjects insertObjects:array atIndexes:indexSet];
        if (_searchField.stringValue.length == 0) {
            [self.projects insertObjects:array atIndexes:indexSet];
        }
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.allProjects, @"object",
                              array, @"array",
                              @"insert", @"operation",
                              indexSet, @"indexSet", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECTROOT_CHANGED object:dict];
    }
    else
    {
        [self.allProjects removeObjectsAtIndexes:indexSet];
        if (_searchField.stringValue.length == 0) {
            [self.projects removeObjectsAtIndexes:indexSet];
        }
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.allProjects, @"object",
                              array, @"array",
                              @"remove", @"operation",
                              indexSet, @"indexSet", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECTROOT_CHANGED object:dict];
    }
}
@end
