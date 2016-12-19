//
//  ProjectDetailViewController.m
//  DTPowerApi
//
//  Created by leks on 13-1-14.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "ProjectDetailViewController.h"
#import "PAApi.h"
#import "PABean.h"
#import "PAImage.h"
#import "BackgroundView.h"
#import "PATableRowView.h"
#import "PATableHeaderCellView.h"
#import "JSON.h"
#import "PAExportEngine.h"
#import "Global.h"

@interface ProjectDetailViewController ()

@end

@implementation ProjectDetailViewController
@synthesize project;
@synthesize paramEditController;
@synthesize postParamEditController;

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]  removeObserver:self];
    [project release];
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
    [basicInfoView reloadObject:self.project];

    PAImage *bg_img = [PAImage imageNamed:@"detail_bg"];
    [bg_img sliceWidth:6 height:6];
    bg.image = bg_img;
    [bg setNeedsDisplay];
    //58, 518
    //158, 518
    currentTabIndex = 0;
    BackgroundView *bgview = (BackgroundView*)self.view;
    bgview.backgroundColor = [NSColor colorWithDeviceRed:236.0/255.0 green:236.0/255.0 blue:236.0/255.0 alpha:1.0];
    
    NSTableHeaderView *tableHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 31)];
    [apisTable setHeaderView:tableHeaderView];
    [apisTable setCornerView:nil];
    [tableHeaderView release];
    
    tableHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 31)];
    [beansTable setHeaderView:tableHeaderView];
    [beansTable setCornerView:nil];
    [tableHeaderView release];
    
    tableHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 31)];
    [commonParamsTable setHeaderView:tableHeaderView];
    [commonParamsTable setCornerView:nil];
    [tableHeaderView release];
    
    tableHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 31)];
    [commonDatasTable setHeaderView:tableHeaderView];
    [commonDatasTable setCornerView:nil];
    [tableHeaderView release];
    
    for (NSTableColumn *column in [apisTable tableColumns])
    {
        PATableHeaderCellView *cell = [[[PATableHeaderCellView alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
    
    for (NSTableColumn *column in [beansTable tableColumns])
    {
        PATableHeaderCellView *cell = [[[PATableHeaderCellView alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
    
    for (NSTableColumn *column in [commonParamsTable tableColumns])
    {
        PATableHeaderCellView *cell = [[[PATableHeaderCellView alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
    
    for (NSTableColumn *column in [commonDatasTable tableColumns])
    {
        PATableHeaderCellView *cell = [[[PATableHeaderCellView alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }

    [commonParamsTable setDoubleAction:@selector(editGetParamAction:)];
    [commonParamsTable setTarget:self];
    [commonDatasTable setDoubleAction:@selector(editPostDataAction:)];
    [commonDatasTable setTarget:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectParamChanged:) name:PANOTIFICATION_PROJECT_PARAMS_CHANGED object:nil];
//    [apisScrollView setBorderColor:[NSColor colorWithDeviceRed:203.0/255.0 green:203.0/255.0 blue:203.0/255.0 alpha:1.0]];
//    [beansScrollView setBorderColor:[NSColor colorWithDeviceRed:203.0/255.0 green:203.0/255.0 blue:203.0/255.0 alpha:1.0]];

//[apisScrollView setNeedsDisplay:YES];
//[beansScrollView setNeedsDisplay:YES];
    

}

-(IBAction)tabAction:(id)sender
{
    if (currentTabIndex == 0)
    {
        //change to project
        [projectView setHidden:NO];
        [basicInfoView setHidden:YES];
        currentTabIndex = 1;
        NSRect r = tabBtn.frame;
        r.origin.x = 58;
        tabBtn.frame = r;
        
        [tabBtn setTitle:@"Common"];
    }
    else if (currentTabIndex == 1)
    {
        //change to common
        [projectView setHidden:YES];
        [basicInfoView setHidden:NO];
        currentTabIndex = 0;
        NSRect r = tabBtn.frame;
        r.origin.x = 158;
        tabBtn.frame = r;
        [tabBtn setTitle:@"Project"];
    }
    
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    PATableRowView *rowview = [[PATableRowView alloc] init];
    rowview.gridColor = tableView.gridColor;
    rowview.parentTableView = tableView;
    return [rowview autorelease];
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

/////////////////////////////////////////////////////////////////

-(IBAction)editGetParamAction:(id)sender
{
    NSInteger selectedRow = [commonParamsTable selectedRow];
    if (selectedRow != -1)
    {
        PAParam *param = [self.project.commonGetParams objectAtIndex:selectedRow];
        self.paramEditController = nil;
        
        if (!self.paramEditController)
        {
            ParamEditController *editController = [[ParamEditController alloc] initWithWindowNibName:@"ParamEditController"];
            self.paramEditController = editController;
            self.paramEditController.pEditDelegate = self;
            [editController release];
        }
        self.paramEditController.project = self.project;
        self.paramEditController.projectMode = YES;
        [self.paramEditController reloadParam:param];
        [[NSApplication sharedApplication] runModalForWindow:self.paramEditController.window];
    }
}

-(IBAction)editPostDataAction:(id)sender
{
    NSInteger selectedRow = [commonDatasTable selectedRow];
    if (selectedRow != -1)
    {
        PAParam *param = [self.project.commonPostDatas objectAtIndex:selectedRow];
        
        self.postParamEditController = nil;
        if (!self.postParamEditController)
        {
            ParamEditController *editController = [[ParamEditController alloc] initWithWindowNibName:@"ParamEditController"];
            self.postParamEditController = editController;
            self.postParamEditController.pEditDelegate = self;
            [editController release];
        }
        
        self.postParamEditController.project = self.project;
        self.postParamEditController.projectMode = YES;
        [self.postParamEditController reloadParam:param];
        [[NSApplication sharedApplication] runModalForWindow:self.postParamEditController.window];
    }
}

-(IBAction)editParamAction:(id)sender
{
    NSButton *btn = (NSButton*)sender;
//    fromSelf = YES;
    //add get param
    if (btn.tag == 1)
    {
        PAParam *p = [self.project defaultGetParam];
        p.rowIndex = self.project.commonGetParams.count;
        [self.project insertParams:[NSArray arrayWithObject:p] isPost:NO];
        [self reloadArrayControllers];
        [commonParamsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:self.project.commonGetParams.count-1] byExtendingSelection:NO];
        [self editGetParamAction:nil];
    }
    //del get param
    else if (btn.tag == 2)
    {
        NSIndexSet *indexSet = commonParamsTable.selectedRowIndexes;
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [project.commonGetParams objectAtIndex:idx];
            [ma addObject:p];
        }];
        
        [self.project removeParams:ma isPost:NO];
        [self reloadArrayControllers];
    }
    //add post data
    else if (btn.tag == 3)
    {
        PAParam *p = [self.project defaultPostParam];
        p.rowIndex = self.project.commonPostDatas.count;
        [self.project insertParams:[NSArray arrayWithObject:p] isPost:YES];
        [self reloadArrayControllers];
        [commonDatasTable selectRowIndexes:[NSIndexSet indexSetWithIndex:self.project.commonPostDatas.count-1] byExtendingSelection:NO];
        [self editPostDataAction:nil];
    }
    //remove post data
    else if (btn.tag == 4)
    {
        NSIndexSet *indexSet = commonDatasTable.selectedRowIndexes;
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [project.commonPostDatas objectAtIndex:idx];
            [ma addObject:p];
        }];
        
        [self.project removeParams:ma isPost:YES];
        [self reloadArrayControllers];
    }
}

-(void)paramEditDidFinished:(ParamEditController*)editController
{
    
}

-(void)projectParamChanged:(NSNotification*)notification
{
    NSDictionary *dict = notification.object;
    PAProject *p = [dict objectForKey:@"object"];
    
    if (p != self.project) {
        return ;
    }
    
    [self reloadArrayControllers];
}

-(void)reloadArrayControllers
{
    [commonGetArrayController rearrangeObjects];
    [commonPostArrayController rearrangeObjects];
}

-(IBAction)copy:(id)sender
{
    if (sender != commonParamsTable &&
        sender != commonDatasTable)
    {
        return ;
    }
    
    NSMutableString *ms = [NSMutableString stringWithCapacity:1000];
    NSMutableArray *ma = [NSMutableArray array];
    
    if (sender == commonParamsTable)
    {
        NSIndexSet *indexSet = commonParamsTable.selectedRowIndexes;
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [project.commonGetParams objectAtIndex:idx];
            [ma addObject:[p toDict]];
        }];
    }
    else if (sender == commonDatasTable)
    {
        NSIndexSet *indexSet = commonDatasTable.selectedRowIndexes;
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [project.commonPostDatas objectAtIndex:idx];
            [ma addObject:[p toDict]];
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
    if (sender != commonParamsTable &&
        sender != commonDatasTable)
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
    
    if (sender == commonParamsTable)
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
                for (int j=0; j<project.commonGetParams.count; j++)
                {
                    PAParam *param = [project.commonGetParams objectAtIndex:j];
                    if ([param.paramKey isEqualToString:k]) {
                        [param setValue:v forKey:@"paramValue"];
                        exists = YES;
                        break;
                    }
                }
                
                if (exists) {
                    continue ;
                }
                PAParam *p = [project defaultGetParam];
                p.name = [project newParamValueByValue:k forKey:@"name" isPost:NO];
                p.paramKey = [project newParamValueByValue:k forKey:@"paramKey" isPost:NO];
                p.paramValue = v;
                p.rowIndex = project.commonGetParams.count+i;
                [ma addObject:p];
            }
            
            if (ma.count>0) {
                [project insertParams:ma isPost:NO];
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
                p.name = [project newParamValueByValue:p.name forKey:@"name" isPost:NO];
                p.paramKey = [project newParamValueByValue:p.paramKey forKey:@"paramKey" isPost:NO];
                p.rowIndex = project.commonGetParams.count + i;
                p.method = PAPARAM_METHOD_GET;
            }
            
            if (ma.count > 0) {
                [project insertParams:ma isPost:NO];
            }
        }
    }
    else if (sender == commonDatasTable)
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
                for (int j=0; j<project.commonPostDatas.count; j++)
                {
                    PAParam *param = [project.commonPostDatas objectAtIndex:j];
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
                
                PAParam *p = [project defaultPostParam];
                p.name = [project newParamValueByValue:k forKey:@"name" isPost:YES];
                p.paramKey = [project newParamValueByValue:k forKey:@"paramKey" isPost:YES];
                p.paramValue = v;
                p.rowIndex = project.commonPostDatas.count+i;
                [ma addObject:p];
            }
            
            if (ma.count>0) {
                [project insertParams:ma isPost:YES];
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
                p.name = [project newParamValueByValue:p.name forKey:@"name" isPost:YES];
                p.paramKey = [project newParamValueByValue:p.paramKey forKey:@"paramKey" isPost:YES];
                p.rowIndex = project.commonPostDatas.count + i;
                p.method = PAPARAM_METHOD_POST;
            }
            
            if (ma.count > 0) {
                [project insertParams:ma isPost:YES];
            }
        }
    }
}

-(IBAction)cut:(id)sender
{
    if (sender != commonParamsTable &&
        sender != commonDatasTable)
    {
        return ;
    }
    
    [self copy:sender];
    
    [self delete:sender];
}

-(IBAction)delete:(id)sender
{
    if (sender == commonParamsTable)
    {
        NSIndexSet *indexSet = commonParamsTable.selectedRowIndexes;
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [project.commonGetParams objectAtIndex:idx];
            [ma addObject:p];
        }];
        
        [self.project removeParams:ma isPost:NO];
        [self reloadArrayControllers];
    }
    else if (sender == commonDatasTable)
    {
        NSIndexSet *indexSet = commonDatasTable.selectedRowIndexes;
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [project.commonPostDatas objectAtIndex:idx];
            [ma addObject:p];
        }];
        
        [self.project removeParams:ma isPost:YES];
        [self reloadArrayControllers];
    }
}

-(void)reloadProject:(PAProject*)newProject
{
    self.project = newProject;
    [basicInfoView reloadObject:newProject];
}
@end
