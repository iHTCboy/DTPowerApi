//
//  DataMappingViewController.m
//  DTPowerApi
//
//  Created by leks on 13-1-23.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "DataMappingViewController.h"
#import "PAField.h"
#import "BeanTypeCellView.h"
#import "PAProject.h"
#import "PAMappingEngine.h"
#import "PAExportEngine.h"
#import "PABean.h"
#import "MyHeaderCell.h"
#import "CustomRowView.h"
#import "PAApiResult.h"
#import "PAImage.h"
#import "FieldWindowController.h"
#import "PAProperty.h"
#import "GlobalSetting.h"
#import "Global.h"
#import "DMTableCellView.h"

//@implementation NSColor (ColorChangingFun)
//
//+(NSArray*)controlAlternatingRowBackgroundColors
//{
//    return [NSArray arrayWithObjects:[NSColor redColor], [NSColor greenColor], nil];
//}
//
//@end

@interface DataMappingViewController ()

@end

@implementation DataMappingViewController
@synthesize api;
@synthesize jsonOutlineView;
@synthesize beanOutlineView;

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [api release];
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

-(void)testHeader
{
    NSTableHeaderView *tableHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 30)];
    [jsonOutlineView setHeaderView:tableHeaderView];
    [jsonOutlineView setCornerView:nil];
    
    NSTableHeaderView *beanHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 30)];
    [beanOutlineView setHeaderView:beanHeaderView];
    [beanOutlineView setCornerView:nil];
    
    [tableHeaderView release];
    [beanHeaderView release];
    
    for (NSTableColumn *column in [jsonOutlineView tableColumns])
    {
         MyHeaderCell *cell = [[[MyHeaderCell alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
    
    for (NSTableColumn *column in [beanOutlineView tableColumns])
    {
        MyHeaderCell *cell = [[[MyHeaderCell alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
    
    [responseView setHidden:YES];
    
    NSShadow *dropShadow = [[NSShadow alloc] init];
    [dropShadow setShadowColor:[NSColor redColor]];
    [dropShadow setShadowOffset:NSMakeSize(10, 10.0)];
    [dropShadow setShadowBlurRadius:10.0];
    
    [beanScrollView setWantsLayer: YES];
    [beanScrollView setShadow: dropShadow];
    
    [dropShadow release];
}

-(void)loadView
{
    [super loadView];
    
    [self testHeader];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiResultSelectionChanged:) name:PANOTIFICATION_APIRESULT_SELECTION_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiSelectionChanged:) name:PANOTIFICATION_APISELECTION_CHANGED object:nil];
    
    
    [[jsonScrollView contentView] setPostsBoundsChangedNotifications: YES];
    [[beanScrollView contentView] setPostsBoundsChangedNotifications: YES];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter] ;
    [center addObserver: self
               selector: @selector(boundsDidChangeNotification:)
                   name: NSViewBoundsDidChangeNotification
                 object: [jsonScrollView contentView]];
    [center addObserver: self
               selector: @selector(boundsDidChangeNotification:)
                   name: NSViewBoundsDidChangeNotification
                 object: [beanScrollView contentView]];
    
    [center addObserver:self
               selector:@selector(tableSelectionDidChangeNotification:)
                   name:NSOutlineViewSelectionDidChangeNotification
                 object:jsonOutlineView];
    [center addObserver:self
               selector:@selector(tableSelectionDidChangeNotification:)
                   name:NSOutlineViewSelectionDidChangeNotification
                 object:beanOutlineView];
    
    [center addObserver:self
               selector:@selector(outlineViewItemDidExpand:)
                   name:NSOutlineViewItemDidExpandNotification
                 object:jsonOutlineView];
    
    [center addObserver:self
               selector:@selector(outlineViewItemDidCollapse:)
                   name:NSOutlineViewItemDidCollapseNotification
                 object:jsonOutlineView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(projectChildrenChanged:)
                                                 name:PANOTIFICATION_PROJECT_CHILDREN_CHANGED
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(beanChildrenChanged:)
                                                 name:PANOTIFICATION_BEAN_CHILDREN_CHANGED
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(projectBeansChanged:)
                                                 name:PANOTIFICATION_PROJECT_BEANS_CHANGED
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToSourceData:) name:PANOTIFICATION_API_PARSE_FALED object:nil];
    
    [log setEditable:NO];
    
    PAImage *table_bg = [PAImage imageNamed:@"datamapping_table_bg"];
    [table_bg sliceWidth:6 height:37];
    beanBackground.image = table_bg;
    jsonBackground.image = table_bg;
    
//    datamapping_table_bg
    PAImage *log_bg = [PAImage imageNamed:@"log_bg"];
    [log_bg sliceWidth:6 height:37];
    logBg.image = log_bg;
    
    PAImage *response_bgimg = [PAImage imageNamed:@"response_bg"];
    [response_bgimg sliceWidth:7 height:46];
    responseBg.image = response_bgimg;
    [responseBg setNeedsDisplay];
    
    PAImage *response_sub_bgimg = [PAImage imageNamed:@"response_sub_bg"];
    [response_sub_bgimg sliceWidth:6 height:6];
    responseSubBg1.image = response_sub_bgimg;
    [responseSubBg1 setNeedsDisplay];
    responseSubBg2.image = response_sub_bgimg;
    [responseSubBg2 setNeedsDisplay];
    
    [jsonOutlineView setDoubleAction:@selector(viewFieldAction:)];
    [jsonOutlineView setTarget:self];
}

- (void)tableSelectionDidChangeNotification:(NSNotification *) notification
{
    NSOutlineView *outlineView = notification.object;
    if (outlineView == jsonOutlineView)
    {
        NSInteger selectedRow = jsonOutlineView.selectedRow;
        if (selectedRow == -1)
        {
            [beanOutlineView deselectAll:nil];
        }
    }
    else if (outlineView == beanOutlineView)
    {
        NSInteger selectedRow = beanOutlineView.selectedRow;
        if (selectedRow == -1)
        {
            [jsonOutlineView deselectAll:nil];
        }
    }
}

- (void)boundsDidChangeNotification: (NSNotification *) notification
{
    static BOOL lock = NO;
    
    if (lock) {
        return ;
    }
    
    NSClipView *obj = notification.object;
    
    NSRect jsr = jsonScrollView.contentView.bounds;
    NSRect br = beanScrollView.contentView.bounds;
    
    if (fabsf(jsr.origin.x - br.origin.x) < 1 &&
        fabsf(jsr.origin.y - br.origin.y) < 1)
    {
        return ;
    }
    
    if (obj == jsonScrollView.contentView)
    {
        lock = YES;
        
        br.origin.y = jsr.origin.y;
        [[beanScrollView contentView] setBounds:br];
        [beanScrollView setNeedsDisplay:YES];
        
//        NSRect hr = beanOutlineView.headerView.bounds;
//        hr.origin.x = jsr.origin.x;
//        [beanOutlineView.headerView setBounds:hr];
//        [beanOutlineView.headerView setNeedsDisplay:YES];

        api.selectedResult.lastResultYOffset = [NSString stringWithFormat:@"%f", jsr.origin.y];
        lock = NO;
    }
    else if (obj == beanScrollView.contentView)
    {
        lock = YES;
        
        jsr.origin.y = br.origin.y;
        [[jsonScrollView contentView] setBounds:jsr];
        [jsonScrollView setNeedsDisplay:YES];
        [jsonOutlineView setNeedsDisplay:YES];
        
//        NSRect hr = jsonOutlineView.headerView.bounds;
//        hr.origin.x = br.origin.x;
//        [jsonOutlineView.headerView setBounds:hr];
//        [jsonOutlineView.headerView setNeedsDisplay:YES];
        api.selectedResult.lastResultYOffset = [NSString stringWithFormat:@"%f", br.origin.y];
        lock = NO;
    }
    
    // 
    
}

-(void)apiSelectionChanged:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAAPI_REQUEST_FINISHED_NOTIFICATION object:self.api];
    
    PAApi *tmpApi = notification.object;
    if (tmpApi)
    {
        self.api = tmpApi;
        [self.api reloadMappingFields];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiLoadFinished:) name:PAAPI_REQUEST_FINISHED_NOTIFICATION object:self.api];
        @synchronized(self)
        {
            [self reloadTables];
        }
    }
}

-(void)apiResultSelectionChanged:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAAPI_REQUEST_FINISHED_NOTIFICATION object:self.api];
    
    NSDictionary *dict = notification.object;
    PAApi *tmpApi = [dict objectForKey:@"object"];
    
    if (tmpApi)
    {
        self.api = nil;
        self.api = tmpApi;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiLoadFinished:) name:PAAPI_REQUEST_FINISHED_NOTIFICATION object:self.api];
    }
    @synchronized(self)
    {
        [self reloadTables];
    }
    
[self reloadResponseString];
}

-(void)apiLoadFinished:(NSNotification*)notification
{
    CGFloat tmp_y = [api.selectedResult.lastResultYOffset floatValue];
    [jsonOutlineView reloadData];
    [beanOutlineView reloadData];
    api.selectedResult.lastResultYOffset = [NSString stringWithFormat:@"%f", tmp_y];
    [self reloadLastOffsetY];
}

-(void)reloadLastOffsetY
{
    CGFloat last_y_offset = [api.selectedResult.lastResultYOffset floatValue];
    NSRect jsr = jsonScrollView.contentView.bounds;
    jsr.origin.y = last_y_offset;
    jsonScrollView.contentView.bounds = jsr;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (splitView == self.view) {
        if (dividerIndex == 0) {
            return 300;
        }
        return self.view.frame.size.height - 80;
    }
    else if (splitView == analyzerContainer)
    {
        return 200;
    }
    
    return 0;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (splitView == self.view) {
        return self.view.frame.size.height - 80;
    }
    else if (splitView == analyzerContainer)
    {
        return self.view.frame.size.width - 200;
    }
    return 0;
}

//- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
//{
//    return 100;
//}
#pragma mark -
#pragma mark ***** Menu Actions *****
-(void)startApi
{
    [self.api start];
}

-(void)mappingField
{
    NSInteger selectedRow = [jsonOutlineView selectedRow];
    id jsonItem = [jsonOutlineView itemAtRow:selectedRow];
    id beanItem = [beanOutlineView itemAtRow:selectedRow];
        
    if (jsonItem && beanItem)
    {
        NSUndoManager *undo = [GlobalSetting undoManager];
        [undo beginUndoGrouping];
        [PAMappingEngine mapJsonField:jsonItem toBeanField:beanItem inProject:api.project forceCreate:NO];
        [undo endUndoGrouping];
    }
}



-(void)removeProperty
{
    NSInteger selectedRow = [jsonOutlineView selectedRow];
    PAField * beanItem = [beanOutlineView itemAtRow:selectedRow];
    
    PABean *bean = [api.project beanForMappingKey:beanItem.parentMappingKey];
    if (bean)
    {
        NSUndoManager *undo = [GlobalSetting undoManager];
        [undo beginUndoGrouping];
        for (int i=0; i<bean.properties.count; i++)
        {
            PAProperty *p = [bean.properties objectAtIndex:i];
            if ([p.fieldName isEqualToString:beanItem.fieldName])
            {
                
                if ([api.project isBeanType:beanItem]) {
                    [api.project removeMapping:beanItem.mappingKey forBeanName:p.beanName];
                }
                [bean removeProperties:[NSArray arrayWithObject:p]];
            }
        }
        [undo endUndoGrouping];
    }
}

-(void)createBeanObject
{
    NSInteger selectedRow = [jsonOutlineView selectedRow];
    PAField *jsonItem = [jsonOutlineView itemAtRow:selectedRow];
    PAField * beanItem = [beanOutlineView itemAtRow:selectedRow];
    
    if (jsonItem && beanItem)
    {
        NSUndoManager *undo = [GlobalSetting undoManager];
        [undo beginUndoGrouping];
        
        if ([jsonItem.parentField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
        {
            jsonItem.fieldName = jsonItem.parentField.fieldName;
        }
        NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:5];
        PABean *b = [PAMappingEngine createBeanForJsonField:jsonItem inProject:api.project toTmpArray:tmpArray];
        b.rowIndex = api.project.beans.allChildren.count;
        
        [api.project insertBeans:[NSArray arrayWithObject:b]];
        [api.project addMapping:jsonItem.mappingKey forBeanName:b.beanName];
        
        [undo endUndoGrouping];
    }
    
    [self reloadTables];
}

-(void)smartAction
{
    NSInteger selectedRow = [jsonOutlineView selectedRow];
    PAField *jsonItem = [jsonOutlineView itemAtRow:selectedRow];
    PAField * beanItem = [beanOutlineView itemAtRow:selectedRow];
    
    if (jsonItem && beanItem)
    {
        NSUndoManager *undo = [GlobalSetting undoManager];
        [undo beginUndoGrouping];
        [PAMappingEngine smartMapJsonField:jsonItem toBeanField:beanItem inProject:api.project];
        [undo endUndoGrouping];
    }
    
//    [api reloadMappingFields];
//    [self reloadTables];
}

-(IBAction)segmentAction:(id)sender
{
    if (segment.selectedSegment == 0) {
        [analyzerContainer setHidden:NO];
        [responseView setHidden:YES];
    }
    else
    {
        [analyzerContainer setHidden:YES];
        [responseView setHidden:NO];
    }
}

-(IBAction)tabAction:(id)sender
{
    //279, 359
    if (currentTabIndex == 0 || sender == nil)
    {
        //change to responseView
        [analyzerContainer setHidden:YES];
        [responseView setHidden:NO];
        currentTabIndex = 1;
        NSRect r = tabBtn.frame;
        r.origin.x = 0;
        tabBtn.frame = r;
        
        [tabBtn setTitle:@"Mapping"];
    }
    else if (currentTabIndex == 1 && sender != nil)
    {
        //change to common
        [responseView setHidden:YES];
        [analyzerContainer setHidden:NO];
        currentTabIndex = 0;
        NSRect r = tabBtn.frame;
        r.origin.x = 80;
        tabBtn.frame = r;
        [tabBtn setTitle:@"Response"];
    }
    
}

-(void)switchToSourceData:(NSNotification*)notification
{
//    [segment setSelectedSegment:1];
//    [self segmentAction:segment];
    [self tabAction:nil];
}

#pragma mark -
#pragma mark ***** NSOutlineView Required Methods (unless bindings are used) *****

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (outlineView == jsonOutlineView)
    {
        if (item == nil)
        {
           return api.fields.count;
        }
        else
        {
            PAField *field = (PAField*)item;
            return field.subFields.count;
        }
    }
    else if (outlineView == beanOutlineView)
    {
        if (item == nil) {
            return api.beanFields.count;
        }
        else
        {
            PAField *field = (PAField*)item;
            return field.subFields.count;
        }
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (outlineView == jsonOutlineView)
    {
        if (!item) {
            return [api.fields objectAtIndex:index];
        }
        else
        {
            PAField *field = (PAField*)item;
            return [field.subFields objectAtIndex:index];
        }
    }
    else if (outlineView == beanOutlineView)
    {
        if (!item) {
            return [api.beanFields objectAtIndex:index];
        }
        else
        {
            PAField *field = (PAField*)item;
            return [field.subFields objectAtIndex:index];
        }
    }
    
    return @"";
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (outlineView == jsonOutlineView)
    {
        if (!item) {
            return YES;
        }
        else
        {
            PAField *field = (PAField*)item;
            return field.subFields.count>0;
        }
    }
    else if (outlineView == beanOutlineView)
    {
        if (!item) {
            return YES;
        }
        else
        {
            PAField *field = (PAField*)item;
            return field.subFields.count>0;
        }
    }
    
    return NO;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    NSDictionary *colors = PAFIELD_TYPE_COLORS;
    NSArray *statusColors = PAFIELD_STATUS_COLORS;
    
    NSTableCellView *cell = nil;
    PAField *field = (PAField*)item;
    cell.textField.textColor = PAFIELD_COLOR_COMMON;
    
    if ([tableColumn.identifier isEqualToString:@"name"])
    {
        cell = [outlineView makeViewWithIdentifier:@"name" owner:self];
        cell.textField.stringValue = field.fieldName;
        
        if (outlineView == beanOutlineView) {
            cell.textField.textColor = PAFIELD_NAME_COLOR_COMMON;
        }
        else
        {
            cell.textField.textColor = PAFIELD_COLOR_COMMON;
        }
        cell.textField.font = PAFIELD_FONT_COMMON;
        
        if (field.fromProperty)
        {
            cell.textField.textColor = PAFIELD_NAME_COLOR_PROPERTY;
        }
        if(field.fromProperty || [api.project isBeanType:field])
        {
//            cell.textField.textColor = [NSColor orangeColor];
            cell.textField.font = PAFIELD_FONT_BOLD;
        }
        else if ([field.fieldType isEqualToString:PAFIELD_TYPE_EMPTY])
        {
            cell.textField.textColor = PAFIELD_COLOR_EMPTY;
            ;
        }
        else
        {
//            cell.textField.textColor = [NSColor blackColor];
        }
        
        
    }
    else if ([tableColumn.identifier isEqualToString:@"type"])
    {
        cell = [outlineView makeViewWithIdentifier:@"type" owner:self];
        cell.textField.stringValue = field.fieldType;
        cell.textField.textColor = PAFIELD_COLOR_COMMON;
        cell.textField.font = PAFIELD_FONT_COMMON;
        
//        cell.imageView.image = [NSImage imageNamed:@"NSAdvanced"];
        
        if ([api.project isBeanType:field])
        {
            cell.imageView.image = [NSImage imageNamed:@"symbol_bean"];
        }
        else if ([field.fieldType isEqualToString:PAFIELD_TYPE_EMPTY])
        {
            cell.imageView.image = [NSImage imageNamed:@"symbol_empty"];;
            cell.textField.textColor = PAFIELD_COLOR_EMPTY;
        }
        else if ([field.fieldType isEqualToString:PAFIELD_TYPE_NULL])
        {
            cell.imageView.image = [NSImage imageNamed:@"symbol_null"];;
        }
        else if ([field.fieldType isEqualToString:PAFIELD_TYPE_STRING])
        {
            cell.imageView.image = [NSImage imageNamed:@"symbol_string"];;
        }
        else if ([field.fieldType isEqualToString:PAFIELD_TYPE_NUMBER])
        {
            cell.imageView.image = [NSImage imageNamed:@"symbol_number"];;
        }
        else if ([field.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
        {
            cell.imageView.image = [NSImage imageNamed:@"symbol_object"];;
        }
        else if ([field.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
        {
            cell.imageView.image = [NSImage imageNamed:@"symbol_array"];;
        }
        
        if (outlineView == beanOutlineView)
        {
            BeanTypeCellView *tmp = (BeanTypeCellView*)cell;
            tmp.btDelegate = self;
            tmp.field = field;
            
            if ([field.fieldType isEqualToString:PAFIELD_TYPE_UNDEFINED] ||
                [field.fieldType isEqualToString:PAFIELD_TYPE_OBJECT] ||
                [api.project isBeanType:field])
            {
                [tmp.popupBtn removeAllItems];
                [tmp.popupBtn addItemWithTitle:PAFIELD_TYPE_UNDEFINED];
                [tmp.popupBtn addItemsWithTitles:[api.project beanNames]];
                [tmp.popupBtn setTitle:field.fieldType];
                
                [tmp.textField setHidden:YES];
                [tmp.popupBtn setHidden:NO];
            }
            else
            {
                if ([field.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
                {
                    NSString *subType = @"";
                    if (field.subFields.count > 0) {
                        PAField *subField = [field.subFields objectAtIndex:0];
                        subType = subField.fieldType;
                    }
                    else if (field.fromProperty)
                    {
                        subType = field.beanName;
                    }
                    
                    tmp.textField.stringValue = [NSString stringWithFormat:@"%@(%@)", PAFIELD_TYPE_ARRAY, subType];
                }
                
                [tmp.textField setHidden:NO];
                [tmp.popupBtn setHidden:YES];
            }
        }
        
        if ([field.fieldType isEqualToString:PAFIELD_TYPE_EMPTY])
        {
//            cell.textField.textColor = [colors objectForKey:field.fieldType];
        }
        else
        {
//            cell.textField.textColor = [NSColor blackColor];
        }
    }
    else if ([tableColumn.identifier isEqualToString:@"matching"])
    {
        cell = [outlineView makeViewWithIdentifier:@"matching" owner:self];
        cell.imageView.image = nil;
        cell.textField.stringValue = @"";
        cell.textField.textColor = PAFIELD_COLOR_COMMON;
        cell.textField.font = PAFIELD_FONT_COMMON;
        
        switch (field.linkStatus)
        {
            case kPAFieldLinkStatusUndefined:
                cell.textField.stringValue = @"Undefined";
                break;
            case kPAFieldLinkStatusNotLink:
//                cell.textField.stringValue = @"not link";
                break;
            case kPAFieldLinkStatusOK:
//                cell.textField.stringValue = @"OK";
                cell.imageView.image = [NSImage imageNamed:@"symbol_ok"];
                break;
            case kPAFieldLinkStatusFail:
//                cell.textField.stringValue = @"Fail";
                cell.imageView.image = [NSImage imageNamed:@"symbol_fail"];
                break;
            default:
                break;
        }
        cell.textField.textColor = [statusColors objectAtIndex:field.linkStatus];
    }
    else if ([tableColumn.identifier isEqualToString:@"value"])
    {
        cell = [outlineView makeViewWithIdentifier:@"value" owner:self];
        cell.textField.stringValue =  field.fieldValue;
        cell.textField.textColor = PAFIELD_COLOR_COMMON;
        cell.textField.font = PAFIELD_FONT_COMMON;
//        cell.textField.textColor = [NSColor blackColor];
    }

    DMTableCellView *tmp = (DMTableCellView*)cell;
    tmp.normalColor = cell.textField.textColor;
    tmp.highlightedColor = [NSColor whiteColor];

    return cell;
}

//- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
//{
//    return 25;
//}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
    NSString *key = [NSString stringWithFormat:@"%p", item];
    id destItem = [api.synTableMapping objectForKey:key];
    
    if (outlineView == jsonOutlineView)
    {
        BOOL expanded = [beanOutlineView isItemExpanded:destItem];
        if (!expanded)
        {
            [beanOutlineView performSelector:@selector(expandItem:) withObject:destItem afterDelay:0.01];
//            [beanOutlineView expandItem:destItem];
        }
    }
    else if (outlineView == beanOutlineView)
    {
        BOOL expanded = [jsonOutlineView isItemExpanded:destItem];
        if (!expanded)
        {
            [jsonOutlineView performSelector:@selector(expandItem:) withObject:destItem afterDelay:0.01];
//            [jsonOutlineView expandItem:destItem];
        }
    }
    
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item
{
    NSString *key = [NSString stringWithFormat:@"%p", item];
    id destItem = [api.synTableMapping objectForKey:key];
    
    if (outlineView == jsonOutlineView)
    {
        BOOL expanded = [beanOutlineView isItemExpanded:destItem];
        if (expanded)
        {
            [beanOutlineView performSelector:@selector(collapseItem:) withObject:destItem afterDelay:0.1];
//            [beanOutlineView collapseItem:destItem];
        }
    }
    else if (outlineView == beanOutlineView)
    {
        BOOL expanded = [jsonOutlineView isItemExpanded:destItem];
        if (expanded)
        {
            [jsonOutlineView performSelector:@selector(collapseItem:) withObject:destItem afterDelay:0.1];
//            [jsonOutlineView collapseItem:destItem];
        }
    }
    
    return YES;
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
    //save expand states
//    [api.expandedItems removeAllObjects];
    if (fromAutoExpand) {
        return ;
    }
    
    [api.selectedResult.expandedItems removeAllObjects];
    for (int i=0; i<jsonOutlineView.numberOfRows; i++)
    {
        PAField *item = [jsonOutlineView itemAtRow:i];
        NSString *si = [NSString stringWithFormat:@"%d", i];
        if ([jsonOutlineView isItemExpanded:item])
        {
            [api.selectedResult.expandedItems addObject:si];
        }
    }
    
    [api.selectedResult.expandedItems sortUsingSelector:@selector(compare:)];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
    //save expand states
//    [api.expandedItems removeAllObjects];
    [api.selectedResult.expandedItems removeAllObjects];
    for (int i=0; i<jsonOutlineView.numberOfRows; i++)
    {
        PAField *item = [jsonOutlineView itemAtRow:i];
        NSString *si = [NSString stringWithFormat:@"%d", i];
        if ([jsonOutlineView isItemExpanded:item])
        {
            [api.selectedResult.expandedItems addObject:si];
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if (outlineView == jsonOutlineView)
    {
        NSInteger selectedRow = [jsonOutlineView rowForItem:item];
        if (selectedRow != beanOutlineView.selectedRow)
        {
            [beanOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
        }
    }
    else if (outlineView == beanOutlineView)
    {
        NSInteger selectedRow = [beanOutlineView rowForItem:item];
        if (selectedRow != jsonOutlineView.selectedRow)
        {
            [jsonOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
        }
    }
    return YES;
}

//double click header edge to resize the column
//- (void)outlineView:(NSOutlineView *)outlineView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn;
//{
//    // tableColumn is actually useless info because the resizing cursor
//    //zone overlaps both adjacent columns.
//    // The resizing zone appears to be the last 3 pixels of the column,
//    //and the first 2 pixels of the next column.
//    NSEvent *event = [NSApp currentEvent];
//    NSPoint location = [event locationInWindow];
//    NSTableHeaderView *header = [outlineView headerView];
//    location = [header convertPoint:location fromView:nil];
//    // offset point 2 pixels to bring it entirely onto the column being
//    //resized
//    if (location.x>=2.0)
//        location.x-=2;
//    
//    NSInteger columnIndex = [header columnAtPoint:location];
//    //NSRect columnRectt = [header headerRectOfColumn:columnIndex];
//    NSRect columnRect = [outlineView rectOfColumn:columnIndex];
//    
//    // slice the 5 pixels on the right edge where the resize happens
//    NSRect slice, remainder;
//    NSDivideRect (columnRect, &slice, &remainder, 5, NSMaxXEdge);
//    
//    if ((NSPointInRect(location,slice)==YES) && [event clickCount]==2)
//    {
//        NSLog(@"autosize column: %@",[[[[outlineView tableColumns]
//                                        objectAtIndex:columnIndex] headerCell] stringValue]);
//        CGFloat maxWidth = 0;
//        
//        for (int i=0; i<outlineView.numberOfRows; i++)
//        {
//            NSTableRowView *row = [outlineView rowViewAtRow:i makeIfNecessary:NO];
//            NSTableCellView *v = [row viewAtColumn:0];
//            [v.textField sizeToFit];
//            NSRect r = v.textField.frame;
//            if (v.frame.origin.x + r.size.width > maxWidth) {
//                maxWidth = v.frame.origin.x + r.size.width;
//            }
//        }
//        
//        for (int i=0; i<outlineView.numberOfRows; i++)
//        {
//            NSTableRowView *row = [outlineView rowViewAtRow:i makeIfNecessary:NO];
//            NSTableCellView *v = [row viewAtColumn:0];
//            NSRect r = v.textField.frame;
//            r.size.width = maxWidth - r.origin.x;
//            v.textField.frame = r;
//            
//            NSRect rv = v.frame;
//            rv.size.width = r.origin.x + r.size.width;
//            v.frame = rv;
//        }
//        
//        [tableColumn setWidth:maxWidth];
//    }
//    
//}

- (CGFloat)outlineView:(NSOutlineView *)outlineView sizeToFitWidthOfColumn:(NSInteger)column
{
    CGFloat maxWidth = 0;
    
    for (int i=0; i<outlineView.numberOfRows; i++)
    {
        NSTableRowView *row = [outlineView rowViewAtRow:i makeIfNecessary:NO];
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
        
        if (r.origin.x + r.size.width + 16.0*([outlineView levelForRow:i]+1)> maxWidth)
        {
            maxWidth = r.origin.x + r.size.width + 16.0*([outlineView levelForRow:i]+1) + 2;
        }
    }
    
//    for (int i=0; i<outlineView.numberOfRows; i++)
//    {
//        NSTableRowView *row = [outlineView rowViewAtRow:i makeIfNecessary:NO];
//        NSTableCellView *v = [row viewAtColumn:column];
//        
////        NSRect rv = v.frame;
////        rv.size.width = maxWidth;
////        v.frame = rv;
//        
//        NSRect r = v.textField.frame;
//        r.size.width = maxWidth - r.origin.x;
//        v.textField.frame = r;
//        
//        if ([v isKindOfClass:[BeanTypeCellView class]])
//        {
//            r = [(BeanTypeCellView*)v popupBtn].frame;
//            r.size.width = maxWidth - r.origin.x;
//            [(BeanTypeCellView*)v popupBtn].frame = r;
//            
//            [[(BeanTypeCellView*)v popupBtn] sizeToFit];
//        }
//    }
    
    return maxWidth;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
    CustomRowView *rowview = [[CustomRowView alloc] init];
//    rowview.backgroundColor = [NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    rowview.gridColor = outlineView.gridColor;
    rowview.parentOutlineView = outlineView;
    return [rowview autorelease];
}

- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    CustomRowView *crv = (CustomRowView*)rowView;
    crv.rowIndex = row;
//    if (row % 2 == 0) {
//        rowView.backgroundColor = [NSColor colorWithDeviceRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:1.0];
//    }
//    else
//    {
//        rowView.backgroundColor = [NSColor colorWithDeviceRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0];
//    }
}

#pragma mark -
#pragma mark ***** Actions *****
-(IBAction)mappingJsonFieldToBeanFieldAction:(id)sender
{
    NSInteger selectedRow = [jsonOutlineView selectedRow];
    PAField *jsonField = [jsonOutlineView itemAtRow:selectedRow];
    PAField *beanField = [beanOutlineView itemAtRow:selectedRow];
    
    if (![PAMappingEngine canMapFromJsonField:jsonField toBeanField:beanField inProject:api.project])
    {
        return ;
    }
    
    [PAMappingEngine mapJsonField:jsonField toBeanField:beanField inProject:api.project forceCreate:NO];
//    [api reloadMappingFields];
//    
//    [self reloadTables];
}

-(void)reloadTables
{
    NSInteger last_select_row = jsonOutlineView.selectedRow;
    CGFloat tmp_y = [api.selectedResult.lastResultYOffset floatValue];
    [jsonOutlineView reloadItem:nil reloadChildren:YES];
    [beanOutlineView reloadItem:nil reloadChildren:YES];
    [self reloadExpandedItems];
    api.selectedResult.lastResultYOffset = [NSString stringWithFormat:@"%f", tmp_y];
    [self reloadLastOffsetY];
//    [beanOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:last_select_row] byExtendingSelection:NO];
//    [jsonOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:last_select_row] byExtendingSelection:NO];
    
    [gWindowController reloadMappingMenuStatus];
}

-(void)reloadExpandedItems
{
    fromAutoExpand = YES;
    for (int i=0;i<api.selectedResult.expandedItems.count; i++)
    {
        NSString *itemIndex = [api.selectedResult.expandedItems objectAtIndex:i];
        if (itemIndex.integerValue < jsonOutlineView.numberOfRows)
        {
            [jsonOutlineView expandItem:[jsonOutlineView itemAtRow:itemIndex.integerValue]];
            [beanOutlineView expandItem:[beanOutlineView itemAtRow:itemIndex.integerValue]];
        }
    }
    fromAutoExpand = NO;
}

//Object Type reselect action
-(void)beanType:(BeanTypeCellView*)cell DidChangedTo:(NSString*)type forField:(PAField*)field;
{
    if (![field.fieldType isEqualToString:PAFIELD_TYPE_UNDEFINED] &&
        ![field.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
    {
        NSString *msg = [NSString stringWithFormat:@"Are you sure to unlink the Bean %@?", cell.lastType];
        NSAlert *alert = [NSAlert alertWithMessageText:msg defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@""];
        NSInteger result = [alert runModal];
        
        if (result == NSAlertDefaultReturn)
        {
            if ([type isEqualToString:PAFIELD_TYPE_UNDEFINED])
            {
                [api.project removeMapping:field.mappingKey forBeanName:cell.lastType];
            }
            else
            {
                NSUndoManager *undo = [GlobalSetting undoManager];
                [undo beginUndoGrouping];
                [api.project removeMapping:field.mappingKey forBeanName:cell.lastType];
                [api.project addMapping:field.mappingKey forBeanName:type];
                [undo endUndoGrouping];
            }
        }
        else
        {
            [cell.popupBtn selectItemWithTitle:cell.lastType];
        }
    }
    else
    {
        [api.project addMapping:field.mappingKey forBeanName:type];
    }
}

-(IBAction)clearLog:(id)sender
{
    [self.api clearLog];
    log.string = @"";
}

-(void)projectChildrenChanged:(NSNotification*)notification
{
    
}

-(void)beanChildrenChanged:(NSNotification*)notification
{
    [api reloadMappingFields];
    
    [self reloadTables];
}

-(void)projectBeansChanged:(NSNotification*)notification
{
    [api reloadMappingFields];
    
    [self reloadTables];
}


-(void)reloadResponseString
{
    if (!self.api.selectedResult) {
        [responseTextView setEditable:YES];
        [responseTextView setString:@""];
        [responseTextView setEditable:NO];
        [responseTextView setNeedsLayout:YES];
        [responseTextView setNeedsDisplay:YES];
        return ;
    }
    
     NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] init];
    [mas appendAttributedString:[PAApi attributedString:@"\nResponse Body:\n\n" color:[NSColor blackColor] fontSize:17 bold:YES]];
    
    [mas appendAttributedString:[PAApi attributedString:self.api.selectedResult.responseJsonString color:[NSColor blueColor] fontSize:13 bold:NO]];
    
    [mas appendAttributedString:[PAApi attributedString:@"\n\nResponse Headers:\n\n" color:[NSColor blackColor] fontSize:17 bold:YES]];
    
    [mas appendAttributedString:[PAApi attributedString:self.api.selectedResult.responseHeaders color:[NSColor darkGrayColor] fontSize:13 bold:NO]];
    
    [responseTextView setEditable:YES];
    [responseTextView setString:@""];
    [responseTextView insertText:mas];
    [responseTextView setEditable:NO];
    //    previewView.attributedString = mas;
    //    previewView.string = ms;
    [responseTextView setNeedsLayout:YES];
    [responseTextView setNeedsDisplay:YES];
    
    [responseTextView scrollToBeginningOfDocument:nil];
}

-(void)viewFieldAction:(id)sender
{
    NSInteger selectedRow = [jsonOutlineView selectedRow];
    PAField *field = [jsonOutlineView itemAtRow:selectedRow];
    if ([field.fieldType isEqualToString:PAFIELD_TYPE_STRING] ||
        [field.fieldType isEqualToString:PAFIELD_TYPE_NUMBER])
    {
        FieldWindowController *fieldWindow = [[FieldWindowController alloc] initWithWindowNibName:@"FieldWindowController"];
        fieldWindow.field = field;
        [[NSApplication sharedApplication] runModalForWindow:fieldWindow.window];
        [fieldWindow release];
    }
}
@end
