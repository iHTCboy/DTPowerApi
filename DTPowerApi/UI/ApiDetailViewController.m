//
//  ApiDetailViewController.m
//  DTPowerApi
//
//  Created by leks on 13-1-14.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "ApiDetailViewController.h"
#import "PAParam.h"
#import "ParamEditController.h"
#import "Global.h"
#import "PAParamGroup.h"
#import "PAApiResult.h"
#import "JSON.h"
#import "PAExportEngine.h"
#import "DTUtil.h"
#import "PAImage.h"
#import "BackgroundView.h"
#import "PATableRowView.h"
#import "PATableHeaderCellView.h"
#import "PAProject.h"

@interface ApiDetailViewController ()

@end

@implementation ApiDetailViewController
@synthesize api;
@synthesize paramEditController;
@synthesize postParamEditController;

-(void)dealloc
{
    [[GlobalSetting undoManager] removeAllActionsWithTarget:self];
    if (api) {
        [[GlobalSetting undoManager] removeAllActionsWithTarget:api];
    }
    
    [api release];
    [paramEditController release];
    [postParamEditController release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)loadView
{
    [super loadView];
    
    PAImage *bg_img = [PAImage imageNamed:@"detail_bg"];
    [bg_img sliceWidth:6 height:6];
    bg.image = bg_img;
    [bg setNeedsDisplay];
    bottomBg.image = bg_img;
    [bottomBg setNeedsDisplay];
    
    [self initTableUI];
    
    [basicInfoView reloadObject:self.api];
    [paramsTable setDoubleAction:@selector(editGetParamAction:)];
    [paramsTable setTarget:self];
    [datasTable setDoubleAction:@selector(editPostDataAction:)];
    [datasTable setTarget:self];
    
    [self reloadPreview];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification object:resultTable queue:nil usingBlock:^(NSNotification *note) {
        NSInteger srow = resultTable.selectedRow;
        if (srow >= 0) {
            @synchronized(self.api)
            {
                [self.api switchResult:[self.api.results objectAtIndex:srow]];
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.api, @"object", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_APIRESULT_SELECTION_CHANGED object:dict];
            }
        }
        else
        {
            @synchronized(self.api)
            {
                [self.api switchResult:nil];
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.api, @"object", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_APIRESULT_SELECTION_CHANGED object:dict];
            }
        }
        
        if (srow < 0) {
            srow = 0;
        }
        
        api.lastSelectedResultIndex = [NSString stringWithFormat:@"%ld", srow];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification object:paramGroupsTable queue:nil usingBlock:^(NSNotification *note) {
        NSInteger srow = paramGroupsTable.selectedRow;
        if (srow >= 0) {
            self.api.selectedParamGroup = [self.api.paramGroups objectAtIndex:srow];
            [self reloadPreview];
        }
        
        if (srow < 0) {
            srow = 0;
        }
        
        api.lastSelectedParamGroup = [NSString stringWithFormat:@"%ld", srow];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PANOTIFICATION_APISELECTION_CHANGED object:nil queue:nil usingBlock:^(NSNotification *note) {
        id item = note.object;
        [self reloadApi:item];
        if (self.api.status == PAApiStatusRunning) {
            [resultTable setEnabled:NO];
        }
        else
        {
            [resultTable setEnabled:YES];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PANOTIFICATION_API_STATUS_CHANGED object:nil queue:nil usingBlock:^(NSNotification *note) {
        if (self.api.status == PAApiStatusRunning) {
            [resultTable setEnabled:NO];
        }
        else
        {
            [resultTable setEnabled:YES];
        }
    }];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PANOTIFICATION_OBJECT_VALUE_CHANGED object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self reloadPreview];
    }];
//    [paramsTable setDataSource:self];
//    [paramsTable registerForDraggedTypes:[NSArray arrayWithObject:NSPasteboardTypeString]];
//    [datasTable registerForDraggedTypes:[NSArray arrayWithObject:NSPasteboardTypeString]];
//    [resultTable registerForDraggedTypes:[NSArray arrayWithObject:NSPasteboardTypeString]];
//    [paramGroupsTable registerForDraggedTypes:[NSArray arrayWithObject:NSPasteboardTypeString]];

}

-(void)initTableUI
{
    NSTableHeaderView *tableHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 30)];
    [paramsTable setHeaderView:tableHeaderView];
    [paramsTable setCornerView:nil];
    [tableHeaderView release];
    
    tableHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 30)];
    [datasTable setHeaderView:tableHeaderView];
    [datasTable setCornerView:nil];
    [tableHeaderView release];
    
    tableHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 30)];
    [resultTable setHeaderView:tableHeaderView];
    [resultTable setCornerView:nil];
    [tableHeaderView release];
    
    tableHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 30)];
    [paramGroupsTable setHeaderView:tableHeaderView];
    [paramGroupsTable setCornerView:nil];
    [tableHeaderView release];
    
    for (NSTableColumn *column in [paramsTable tableColumns])
    {
        PATableHeaderCellView *cell = [[[PATableHeaderCellView alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
    
    for (NSTableColumn *column in [datasTable tableColumns])
    {
        PATableHeaderCellView *cell = [[[PATableHeaderCellView alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
    
    for (NSTableColumn *column in [resultTable tableColumns])
    {
        PATableHeaderCellView *cell = [[[PATableHeaderCellView alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
    
    for (NSTableColumn *column in [paramGroupsTable tableColumns])
    {
        PATableHeaderCellView *cell = [[[PATableHeaderCellView alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    PATableRowView *rowview = [[PATableRowView alloc] init];
    rowview.gridColor = tableView.gridColor;
    rowview.parentTableView = tableView;
    return [rowview autorelease];
}

-(IBAction)tabAction:(id)sender
{
    if (currentTabIndex == 0)
    {
        //change to project
        [apiView setHidden:NO];
        [basicInfoView setHidden:YES];
        currentTabIndex = 1;
        NSRect r = upTabBtn.frame;
        r.origin.x = 58;
        upTabBtn.frame = r;
        
        [upTabBtn setTitle:@"Common"];
    }
    else if (currentTabIndex == 1)
    {
        //change to common
        [apiView setHidden:YES];
        [basicInfoView setHidden:NO];
        currentTabIndex = 0;
        NSRect r = upTabBtn.frame;
        r.origin.x = 158;
        upTabBtn.frame = r;
        [upTabBtn setTitle:@"Api"];
    }
    
}

-(IBAction)bottomTabAction:(id)sender
{
    if (currentBottomTabIndex == 0)
    {
        //change to project
        [resultView setHidden:NO];
        [paramGroupsView setHidden:YES];
        currentBottomTabIndex = 1;
        NSRect r = bottomTabBtn.frame;
        r.origin.x = 58;
        bottomTabBtn.frame = r;
        
        [bottomTabBtn setTitle:@"Param Groups"];
    }
    else if (currentBottomTabIndex == 1)
    {
        //change to common
        [resultView setHidden:YES];
        [paramGroupsView setHidden:NO];
        currentBottomTabIndex = 0;
        NSRect r = bottomTabBtn.frame;
        r.origin.x = 158;
        bottomTabBtn.frame = r;
        [bottomTabBtn setTitle:@"Results"];
    }
    
}

-(void)reloadApi:(PAApi*)newApi
{
    [[GlobalSetting undoManager] removeAllActionsWithTarget:self];
    if (api) {
        [[GlobalSetting undoManager] removeAllActionsWithTarget:api];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAAPI_REQUEST_FINISHED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PANOTIFICATION_API_CHILDREN_CHANGED object:nil];
    
    NSString *tmpResultRow = newApi.lastSelectedResultIndex;
    NSString *tmpGroupRow = newApi.lastSelectedParamGroup;
    
    self.api = newApi;
    [basicInfoView reloadObject:newApi];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiLoadFinished:) name:PAAPI_REQUEST_FINISHED_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(apiChildrenChanged:)
                                                 name:PANOTIFICATION_API_CHILDREN_CHANGED
                                               object:nil];
    
    [self reloadArrayControllers];
    api.lastSelectedResultIndex = tmpResultRow;
    api.lastSelectedParamGroup = tmpGroupRow;
    
    [autoCreateResultBtn setState:self.api.autoCreateNewResult.boolValue];
    [dupSelectedBtn setState:self.api.dupSelectedGroup.boolValue];
    [self reloadPreview];
    
    [resultTable selectRowIndexes:[NSIndexSet indexSetWithIndex:api.lastSelectedResultIndex.integerValue] byExtendingSelection:NO];
    [paramGroupsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:api.lastSelectedParamGroup.integerValue] byExtendingSelection:NO];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.api, @"object", nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_APIRESULT_SELECTION_CHANGED object:dict];
}

-(void)apiLoadFinished:(NSNotification*)notification
{
    NSUInteger sidx = [self.api.results indexOfObject:self.api.selectedResult];
    [self reloadArrayControllers];
    [resultTable selectRowIndexes:[NSIndexSet indexSetWithIndex:sidx] byExtendingSelection:NO];
}

-(void)apiChildrenChanged:(NSNotification*)notification
{
    NSDictionary *dict = notification.object;
    PAApi *a = [dict objectForKey:@"object"];
    NSString *type = [dict objectForKey:@"type"];
    
    if (a != self.api) {
        return ;
    }
    
    if ([type isEqualToString:@"result"])
    {
        NSInteger rsrow = 0;
        for (int i=0; i<a.results.count; i++)
        {
            PAApiResult *r = [a.results objectAtIndex:i];
            if (r == a.selectedResult)
            {
                rsrow = i;
                break;
            }
        }
        
        if (addingResult) {
            rsrow = a.results.count - 1;
            addingResult = NO;
        }
        
        [resultsGroupArrayController rearrangeObjects];
        a.lastSelectedResultIndex = [NSString stringWithFormat:@"%ld", rsrow];
        [resultTable selectRowIndexes:[NSIndexSet indexSetWithIndex:rsrow] byExtendingSelection:NO];
    }
    else if ([type isEqualToString:@"paramGroup"])
    {
        NSInteger psrow = 0;
        for (int i=0; i<a.paramGroups.count; i++) {
            PAParamGroup *p = [a.paramGroups objectAtIndex:i];
            if (p == a.selectedParamGroup) {
                psrow = i;
                break;
            }
        }
        
        if (addingParamGroup) {
            psrow = a.results.count - 1;
            addingParamGroup = NO;
        }
        
        [paramGroupArrayController rearrangeObjects];
        a.lastSelectedParamGroup = [NSString stringWithFormat:@"%ld", psrow];
        [paramGroupsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:psrow] byExtendingSelection:NO];
    }
    else if ([type isEqualToString:@"param"])
    {
        [getParamArrayController rearrangeObjects];
        [postDataArrayController rearrangeObjects];
    }
    
    [self reloadPreview];
}

#pragma mark -
#pragma mark ***** NSTableView Delegate *****

- (CGFloat)tableView:(NSTableView *)tableView sizeToFitWidthOfColumn:(NSInteger)column
{
    CGFloat maxWidth = 0;
    
    for (int i=0; i<tableView.numberOfRows; i++)
    {
        NSTableRowView *row = [tableView rowViewAtRow:i makeIfNecessary:NO];
        NSTableCellView *v = [row viewAtColumn:column];
        NSRect r = NSZeroRect;
        
        if ([v isKindOfClass:[BeanTypeCellView class]])
        {
            if (v.textField.isHidden)
            {
                BeanTypeCellView *bv = (BeanTypeCellView*)v;
                CGRect tmp = bv.popupBtn.frame;
                [bv.popupBtn sizeToFit];
                r = bv.popupBtn.frame;
                bv.popupBtn.frame = tmp;
            }
            else
            {
                CGRect tmp = v.textField.frame;
                [v.textField sizeToFit];
                r = v.textField.frame;
                v.textField.frame = tmp;
            }
        }
        else
        {
            CGRect tmp = v.textField.frame;
            [v.textField sizeToFit];
            r = v.textField.frame;
            v.textField.frame = tmp;
        }
        
        if (r.origin.x + r.size.width> maxWidth)
        {
            maxWidth = r.origin.x + r.size.width + 2;
        }
    }
        
    return maxWidth;
}

#pragma mark -
#pragma mark ***** Actions *****

-(IBAction)resultSelectionChanged:(id)sender
{
    NSInteger srow = [resultTable selectedRow];
    if (srow > 0) {
        id selectedResult = [api.results objectAtIndex:srow];
        [api switchResult:selectedResult];
    }
    else
    {
        [api switchResult:nil];
    }
    
    
}

-(IBAction)editGetParamAction:(id)sender
{
    NSInteger selectedRow = [paramsTable selectedRow];
    if (selectedRow != -1)
    {
        PAParam *param = [api.selectedParamGroup.getParams objectAtIndex:selectedRow];
        self.paramEditController = nil;
        
        if (!self.paramEditController)
        {
            ParamEditController *editController = [[ParamEditController alloc] initWithWindowNibName:@"ParamEditController"];
            self.paramEditController = editController;
            self.paramEditController.pEditDelegate = self;
            [editController release];
        }
        
        [self.paramEditController reloadParam:param];
        [[NSApplication sharedApplication] runModalForWindow:self.paramEditController.window];
    }
}

-(IBAction)editPostDataAction:(id)sender
{
    NSInteger selectedRow = [datasTable selectedRow];
    if (selectedRow != -1)
    {
        PAParam *param = [api.selectedParamGroup.postDatas objectAtIndex:selectedRow];
        
        self.postParamEditController = nil;
        if (!self.postParamEditController)
        {
            ParamEditController *editController = [[ParamEditController alloc] initWithWindowNibName:@"ParamEditControllerPost"];
            self.postParamEditController = editController;
            self.postParamEditController.pEditDelegate = self;
            [editController release];
        }
        [self.postParamEditController reloadParam:param];
        [[NSApplication sharedApplication] runModalForWindow:self.postParamEditController.window];
    }
}

-(IBAction)editParamAction:(id)sender
{
    NSButton *btn = (NSButton*)sender;
    fromSelf = YES;
    //add get param
    if (btn.tag == 1)
    {
        PAParam *p = [api.selectedParamGroup defaultGetParam];
        p.rowIndex = self.api.selectedParamGroup.getParams.count;
        [self.api.selectedParamGroup insertParams:[NSArray arrayWithObject:p] isPost:NO];

        [getParamArrayController rearrangeObjects];
        [paramsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:api.selectedParamGroup.getParams.count-1] byExtendingSelection:NO];
        
        [self editGetParamAction:nil];
    }
    //del get param
    else if (btn.tag == 2)
    {
        NSIndexSet *indexSet = paramsTable.selectedRowIndexes;
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [api.selectedParamGroup.getParams objectAtIndex:idx];
            [ma addObject:p];
        }];
        
        [self.api.selectedParamGroup removeParams:ma isPost:NO];
        [getParamArrayController rearrangeObjects];
    }
    //add post data
    else if (btn.tag == 3)
    {
        PAParam *p = [api.selectedParamGroup defaultPostParam];
        p.rowIndex = self.api.selectedParamGroup.postDatas.count;
        [self.api.selectedParamGroup insertParams:[NSArray arrayWithObject:p] isPost:YES];
        [postDataArrayController rearrangeObjects];
        
        [datasTable selectRowIndexes:[NSIndexSet indexSetWithIndex:api.selectedParamGroup.postDatas.count-1] byExtendingSelection:NO];
        [self editPostDataAction:nil];
    }
    //remove post data
    else if (btn.tag == 4)
    {
        NSIndexSet *indexSet = datasTable.selectedRowIndexes;
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [api.selectedParamGroup.postDatas objectAtIndex:idx];
            [ma addObject:p];
        }];
        
        [self.api.selectedParamGroup removeParams:ma isPost:YES];
        [postDataArrayController rearrangeObjects];
    }
    fromSelf = NO;
    [self reloadPreview];
}

-(void)reloadPreview
{
//    NSMutableString *ms = [NSMutableString stringWithCapacity:100];
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] init];
    
    if (api.url.length == 0) {
        [mas appendAttributedString:[PAApi attributedString:@"Please specify url first." color:[NSColor redColor] bold:YES]];
//        [ms appendString:@"Please specify url first."];
    }
    else
    {
//        [ms appendString:api.requestUrlString];
        [mas appendAttributedString:[PAApi attributedString:api.requestUrlString color:[NSColor blueColor] bold:YES]];
        NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
        for (int i=0; i<api.selectedParamGroup.postDatas.count; i++)
        {
            PAParam *p = [api.selectedParamGroup.postDatas objectAtIndex:i];
            if ([p.paramType isEqualToString:PAPARAM_TYPE_FILE])
            {
                [md setObject:@"File binary data" forKey:p.paramKey];
            }
            else
            {
                [md setObject:p.paramValue forKey:p.paramKey];
            }
        }
        
        for (int i=0; i<api.project.commonPostDatas.count; i++)
        {
            PAParam *pp = [api.project.commonPostDatas objectAtIndex:i];
            BOOL exists = NO;
            for (int j=0; j<api.selectedParamGroup.postDatas.count; j++)
            {
                PAParam *p = [api.selectedParamGroup.postDatas objectAtIndex:j];
                if ([p.paramKey isEqualToString:pp.paramKey])
                {
                    exists = YES;
                }
            }
            
            if (exists) {
                continue ;
            }
            
            if ([pp.paramType isEqualToString:PAPARAM_TYPE_FILE])
            {
                [md setObject:@"File binary data" forKey:pp.paramKey];
            }
            else
            {
                [md setObject:pp.paramValue forKey:pp.paramKey];
            }
        }
        
        [mas appendAttributedString:[PAApi attributedString:@"\n\nPost datas:\n" color:[NSColor blackColor] bold:YES]];
        NSString *postStr = [NSString stringWithFormat:@"%@", md];
        [mas appendAttributedString:[PAApi attributedString:postStr color:[NSColor greenColor] bold:YES]];
    }
    
    [previewView setEditable:YES];
    [previewView setString:@""];
    [previewView insertText:mas];
    [previewView setEditable:NO];
//    previewView.attributedString = mas;
//    previewView.string = ms;
    [previewView setNeedsLayout:YES];
    [previewView setNeedsDisplay:YES];
}

- (void)scrollToTop
{
    NSPoint newScrollOrigin;
    
    // assume that the scrollview is an existing variable
    if ([[container documentView] isFlipped]) {
        newScrollOrigin=NSMakePoint(0.0,0.0);
    } else {
        newScrollOrigin=NSMakePoint(0.0,NSMaxY([[container documentView] frame])
                                    -NSHeight([[container contentView] bounds]));
    }
    
    [[container documentView] scrollPoint:newScrollOrigin];
    
}

-(IBAction)removeResultAction:(id)sender
{
    NSInteger srow = resultTable.selectedRow;
    if (srow == -1) {
        return ;
    }
    
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure to delete the result?" defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@""];
    NSInteger result = [alert runModal];

    if (result == NSAlertDefaultReturn)
    {
        PAApiResult *sresult = [api.results objectAtIndex:srow];
        [api removeResults:[NSArray arrayWithObject:sresult]];
        if (api.results.count == 0) {
            self.api.lastSelectedResultIndex = @"0";
            
            [self.api switchResult:nil];
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.api, @"object", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_APIRESULT_SELECTION_CHANGED object:dict];
        }
    }
}

-(IBAction)addParamGroupAction:(id)sender
{
    PAParamGroup *pg = nil;
    if (api.dupSelectedGroup.integerValue == 1) {
        pg = [api defaultParamGroup:YES];
    }
    else
    {
        pg = [api defaultParamGroup:NO];
    }
    
    pg.rowIndex = api.paramGroups.count;
    self.api.selectedParamGroup = pg;
    [self.api insertParamGroups:[NSArray arrayWithObject:pg]];
}

-(IBAction)removeParamGroupAction:(id)sender
{
    if (self.api.paramGroups.count == 1) {
        return ;
    }
    PAParamGroup *pg = api.selectedParamGroup;
    [self.api removeParamGroups:[NSArray arrayWithObject:pg]];
}

-(IBAction)copy:(id)sender
{
    if (sender != paramsTable &&
        sender != datasTable &&
        sender != resultTable &&
        sender != paramGroupsTable)
    {
        return ;
    }
    
    NSMutableString *ms = [NSMutableString stringWithCapacity:1000];
    NSMutableArray *ma = [NSMutableArray array];
    
    if (sender == paramsTable)
    {
        NSIndexSet *indexSet = paramsTable.selectedRowIndexes;
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [api.selectedParamGroup.getParams objectAtIndex:idx];
            [ma addObject:[p toDict]];
        }];
    }
    else if (sender == datasTable)
    {
        NSIndexSet *indexSet = datasTable.selectedRowIndexes;
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [api.selectedParamGroup.postDatas objectAtIndex:idx];
            [ma addObject:[p toDict]];
        }];
    }
    else if (sender == resultTable)
    {
        NSIndexSet *indexSet = resultTable.selectedRowIndexes;
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAApiResult *r = [api.results objectAtIndex:idx];
            [ma addObject:[r toDict]];
        }];
    }
    else if (sender == paramGroupsTable)
    {
        NSIndexSet *indexSet = paramGroupsTable.selectedRowIndexes;
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParamGroup *g = [api.paramGroups objectAtIndex:idx];
            [ma addObject:[g toDict]];
        }];
    }
    
    [ms appendString:[ma JSONRepresentation]];
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    NSArray *copiedObjects = [NSArray arrayWithObject:ms];
    [pasteboard writeObjects:copiedObjects];
}

-(IBAction)paste:(id)sender
{
    if (sender != paramsTable &&
        sender != datasTable &&
        sender != resultTable &&
        sender != paramGroupsTable)
    {
        return ;
    }
    
    NSString *pstr = nil;
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[NSString class]];
    NSDictionary *options = [NSDictionary dictionary];
    
    BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];
    if (ok)
    {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        pstr = [objectsToPaste objectAtIndex:0];
    }
    
    if (pstr.length == 0) {
        return ;
    }
    
    NSString *type = [PAExportEngine objectTypeForJsonString:pstr];
    
    if (sender == paramsTable)
    {
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        if ([type isEqualToString:PAOBJECT_NAME_NEW_PARAM] ||
            [type isEqualToString:PAOBJECT_NAME_NEW_API] ||
            [type isEqualToString:PAOBJECT_NAME_NEW_BEAN])
        {
            NSDictionary *dict = nil;
            NSMutableArray *allkeys = [NSMutableArray arrayWithCapacity:10];
            
            if ([type isEqualToString:PAOBJECT_NAME_NEW_PARAM] ||
                [type isEqualToString:PAOBJECT_NAME_NEW_API]) {
                dict = [PAParam parseUrlString:pstr];
                NSArray *tmp = [dict objectForKey:@"$$allkeys$$"];
                if ([tmp isKindOfClass:[NSArray class]]) {
                    [allkeys setArray:tmp];
                }
            }
            else if ([type isEqualToString:PAOBJECT_NAME_NEW_BEAN])
            {
                dict = [pstr JSONValue];
                if (![dict isKindOfClass:[NSDictionary class]])
                {
                    return ;
                }
                //remove all null string keys
                NSArray *keys = [dict allKeys];
                [allkeys setArray:[keys sortedArrayUsingSelector:@selector(compare:)]];
                NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:dict];
                NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
                
                for (NSString *k in keys)
                {
                    id v = [dict objectForKey:k];
                    if ([v isKindOfClass:[NSNumber class]]) {
                        v = [NSString stringWithFormat:@"%@",v];
                        [md setObject:v forKey:k];
                    }
                    else if (![v isKindOfClass:[NSString class]])
                    {
                        [ma addObject:k];
                    }
                }
                
                [md removeObjectsForKeys:ma];
                dict = md;
            }
            
            NSUndoManager *undo = [GlobalSetting undoManager];
            [undo beginUndoGrouping];
            NSArray *keys = allkeys;
            for (int i=0; i<keys.count; i++)
            {
                NSString *k = [keys objectAtIndex:i];
                NSString *v = [dict objectForKey:k];
                BOOL exists = NO;
                for (int j=0; j<api.selectedParamGroup.getParams.count; j++)
                {
                    PAParam *param = [api.selectedParamGroup.getParams objectAtIndex:j];
                    if ([param.paramKey isEqualToString:k]) {
                        [param setValue:v forKey:@"paramValue"];
                        exists = YES;
                        break;
                    }
                    
                    
                }
                
                if (exists) {
                    continue ;
                }
                PAParam *p = [api.selectedParamGroup defaultGetParam];
                p.name = [api.selectedParamGroup newParamValueByValue:k forKey:@"name" isPost:NO];
                p.paramKey = [api.selectedParamGroup newParamValueByValue:k forKey:@"paramKey" isPost:NO];
                p.paramValue = v;
                p.rowIndex = api.selectedParamGroup.getParams.count+i;
                
                [ma addObject:p];
            }
            
            if (ma.count>0) {
                [api.selectedParamGroup insertParams:ma isPost:NO];
            }
            [undo endUndoGrouping];
        }
        else if ([type isEqualToString:PAOBJECT_NAME_PARAM] ||
                 [type isEqualToString:PAOBJECT_NAME_PARAM_ARRAY])
        {   
            NSArray *objs = [PAExportEngine arrayForJsonString:pstr type:type];
            NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
            
            for (int i=0; i<objs.count; i++)
            {
                PAParam *p = [objs objectAtIndex:i];
                if ([p.paramType isEqualToString:PAPARAM_TYPE_FILE]) {
                    continue ;
                }
                [ma addObject:p];
                p.name = [api.selectedParamGroup newParamValueByValue:p.name forKey:@"name" isPost:NO];
                p.paramKey = [api.selectedParamGroup newParamValueByValue:p.paramKey forKey:@"paramKey" isPost:NO];
                p.method = PAPARAM_METHOD_GET;
                p.rowIndex = api.selectedParamGroup.getParams.count + i;
            }
            
            if (ma.count > 0) {
                [api.selectedParamGroup insertParams:ma isPost:NO];
            }
        }
    }
    else if (sender == datasTable)
    {
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        if ([type isEqualToString:PAOBJECT_NAME_NEW_PARAM] ||
            [type isEqualToString:PAOBJECT_NAME_NEW_API] ||
            [type isEqualToString:PAOBJECT_NAME_NEW_BEAN])
        {
            NSDictionary *dict = nil;
            NSMutableArray *allkeys = [NSMutableArray arrayWithCapacity:10];
            
            if ([type isEqualToString:PAOBJECT_NAME_NEW_PARAM] ||
                [type isEqualToString:PAOBJECT_NAME_NEW_API]) {
                dict = [PAParam parseUrlString:pstr];
                NSArray *tmp = [dict objectForKey:@"$$allkeys$$"];
                if ([tmp isKindOfClass:[NSArray class]]) {
                    [allkeys setArray:tmp];
                }
            }
            else if ([type isEqualToString:PAOBJECT_NAME_NEW_BEAN])
            {
                dict = [pstr JSONValue];
                if (![dict isKindOfClass:[NSDictionary class]])
                {
                    return ;
                }
                //remove all null string keys
                NSArray *keys = [dict allKeys];
                [allkeys setArray:[keys sortedArrayUsingSelector:@selector(compare:)]];
                
                NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:dict];
                NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
                
                for (NSString *k in keys)
                {
                    id v = [dict objectForKey:k];
                    if ([v isKindOfClass:[NSNumber class]]) {
                        v = [NSString stringWithFormat:@"%@",v];
                        [md setObject:v forKey:k];
                    }
                    else if (![v isKindOfClass:[NSString class]])
                    {
                        [ma addObject:k];
                    }
                }
                
                [md removeObjectsForKeys:ma];
                dict = md;
            }
            
            NSUndoManager *undo = [GlobalSetting undoManager];
            [undo beginUndoGrouping];

//            NSDictionary *dict = [PAParam parseUrlString:pstr];
            NSArray *keys = allkeys;
            for (int i=0; i<keys.count; i++)
            {
                NSString *k = [keys objectAtIndex:i];
                NSString *v = [dict objectForKey:k];
                BOOL exists = NO;
                for (int j=0; j<api.selectedParamGroup.postDatas.count; j++)
                {
                    PAParam *param = [api.selectedParamGroup.postDatas objectAtIndex:j];
                    if ([param.paramKey isEqualToString:k] &&
                        ([param.paramType isEqualToString:PAPARAM_TYPE_STRING] ||
                         [param.paramType isEqualToString:PAPARAM_TYPE_NUMBER])) {
                        [param setValue:v forKey:@"paramValue"];
                        exists = YES;
                        break;
                    }
                }
                
                if (exists) {
                    continue ;
                }
                
                PAParam *p = [api.selectedParamGroup defaultPostParam];
                p.name = [api.selectedParamGroup newParamValueByValue:k forKey:@"name" isPost:YES];
                p.paramKey = [api.selectedParamGroup newParamValueByValue:k forKey:@"paramKey" isPost:YES];
                p.paramValue = v;
                p.rowIndex = api.selectedParamGroup.postDatas.count+i;
                [ma addObject:p];
            }
            
            if (ma.count>0) {
                [api.selectedParamGroup insertParams:ma isPost:YES];
            }
            [undo endUndoGrouping];
        }
        else if ([type isEqualToString:PAOBJECT_NAME_PARAM] ||
                 [type isEqualToString:PAOBJECT_NAME_PARAM_ARRAY])
        {
            NSArray *objs = [PAExportEngine arrayForJsonString:pstr type:type];
            for (int i=0; i<objs.count; i++)
            {
                PAParam *p = [objs objectAtIndex:i];
                p.name = [api.selectedParamGroup newParamValueByValue:p.name forKey:@"name" isPost:YES];
                p.paramKey = [api.selectedParamGroup newParamValueByValue:p.paramKey forKey:@"paramKey" isPost:YES];
                p.method = PAPARAM_METHOD_POST;
                p.rowIndex = api.selectedParamGroup.getParams.count + i;
            }
            
            [api.selectedParamGroup insertParams:objs isPost:YES];
        }
    }
    else if (sender == resultTable)
    {
        if ([type isEqualToString:PAOBJECT_NAME_APIRESULT] ||
            [type isEqualToString:PAOBJECT_NAME_APIRESULT_ARRAY])
        {
            NSArray *objs = [PAExportEngine arrayForJsonString:pstr type:type];
            for (int i=0; i<objs.count; i++)
            {
                PAApiResult *result = [objs objectAtIndex:i];
                result.name = [api newResultValueByValue:result.name forKey:@"name"];
                result.rowIndex = api.results.count + i;
                result.parentApi = api;
            }
            
            addingResult = YES;
            [api insertResults:objs];
        }
        else if ([type isEqualToString:PAOBJECT_NAME_NEW_BEAN] ||
                 [type isEqualToString:PAOBJECT_NAME_NEW_BEAN_ARRAY])
        {
            PAApiResult *result = [api defaultApiResult];
            result.name = [api newResultValueByValue:@"Offline Result" forKey:@"name"];
            [result resetAsLocal];
            result.responseStatus = @"Offline Result";
            result.responseJsonString = pstr;
            result.rowIndex = api.results.count;
            addingResult = YES;
            [api insertResults:[NSArray arrayWithObject:result]];
        }
    }
    else if (sender == paramGroupsTable)
    {
        if ([type isEqualToString:PAOBJECT_NAME_PARAMGROUP] ||
            [type isEqualToString:PAOBJECT_NAME_PARAMGROUP_ARRAY])
        {
            NSArray *objs = [PAExportEngine arrayForJsonString:pstr type:type];
            for (int i=0; i<objs.count; i++)
            {
                PAParamGroup *pg = [objs objectAtIndex:i];
                pg.name = [api newParamGroupValueByValue:pg.name forKey:@"name"];
                pg.rowIndex = api.paramGroups.count + i;
            }
            
            [api insertParamGroups:objs];
        }
    }
    
}

-(IBAction)cut:(id)sender
{
    if (sender != paramsTable &&
        sender != datasTable)
    {
        return ;
    }
    
    [self copy:sender];
    
    [self delete:sender];
}

-(IBAction)delete:(id)sender
{
    if (sender == paramsTable)
    {
        NSIndexSet *indexSet = paramsTable.selectedRowIndexes;
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [api.selectedParamGroup.getParams objectAtIndex:idx];
            [ma addObject:p];
        }];
        
        [self.api.selectedParamGroup removeParams:ma isPost:NO];
        [self reloadArrayControllers];
    }
    else if (sender == datasTable)
    {
        NSIndexSet *indexSet = datasTable.selectedRowIndexes;
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [api.selectedParamGroup.postDatas objectAtIndex:idx];
            [ma addObject:p];
        }];
        
        [self.api.selectedParamGroup removeParams:ma isPost:YES];
        [self reloadArrayControllers];
    }
}

#pragma mark -
#pragma mark ***** Data Changed Delegates *****

-(void)textFieldDidChanged:(ProjectTextField*)textField
{
    [self reloadPreview];
}

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    [self reloadPreview];
}

- (void)tableView:(NSTableView *)tableView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    [self reloadPreview];
}

-(void)paramEditDidFinished:(ParamEditController*)editController
{
    [self reloadPreview];
}

-(IBAction)checkAction:(id)sender
{
    NSButton *btn = sender;
    if (btn.tag == 11)
    {
        //dup 
        self.api.dupSelectedGroup = [NSString stringWithFormat:@"%ld", [btn state]];
    }
    else if (btn.tag == 12)
    {
        //auto create
        self.api.autoCreateNewResult = [NSString stringWithFormat:@"%ld", [btn state]];
    }
}

-(void)reloadArrayControllers
{
    [getParamArrayController rearrangeObjects];
    [postDataArrayController rearrangeObjects];
    [paramGroupArrayController rearrangeObjects];
    [resultsGroupArrayController rearrangeObjects];
}

#pragma mark -
#pragma mark ***** Drag&Drop Delegate *****
#pragma mark -
/*
- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
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

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    if (dropOperation == NSTableViewDropOn) {
        return NSDragOperationNone;
    }
    
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
    if (!type)
    {
        return NSDragOperationNone;
    }
    
    return NSDragOperationGeneric;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSMutableString *ms = [NSMutableString stringWithCapacity:1000];
//    for (int i=0; i<items.count; i++)
//    {
//        id item = [items objectAtIndex:i];
//        if ([item isKindOfClass:[PAObject class]])
//        {
//            [ms setString:[(PAObject*)item dictString]];
//        }
//    }
    
    [pboard clearContents];
    NSArray *copiedObjects = [NSArray arrayWithObject:ms];
    [pboard writeObjects:copiedObjects];
    NSLog(@"drag:%@", ms);
    return YES;
}
 */
@end
