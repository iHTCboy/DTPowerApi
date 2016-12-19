//
//  BeanDetailViewController.m
//  DTPowerApi
//
//  Created by leks on 13-1-22.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "BeanDetailViewController.h"
#import "PropertyWindowController.h"
#import "Global.h"
#import "PAProject.h"
#import "PATableRowView.h"
#import "PAImage.h"
#import "PATableHeaderCellView.h"
#import "JSON.h"
#import "PAExportEngine.h"

@interface BeanDetailViewController ()

@end

@implementation BeanDetailViewController
@synthesize bean;
@synthesize editPropertyController;
@synthesize connectedApis;
@synthesize contents;
@synthesize connectedApisArrayController;

-(void)dealloc
{
    [[GlobalSetting undoManager] removeAllActionsWithTarget:self];
    if (bean) {
        [[GlobalSetting undoManager] removeAllActionsWithTarget:bean];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [bean release];
    [editPropertyController release];
    [connectedApis release];
    [contents release];
    [connectedApisArrayController release];
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
    //58, 518
    //158, 518
    currentTabIndex = 0;
//    BackgroundView *bgview = (BackgroundView*)self.view;
//    bgview.backgroundColor = [NSColor colorWithDeviceRed:236.0/255.0 green:236.0/255.0 blue:236.0/255.0 alpha:1.0];
    
    NSTableHeaderView *tableHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 30)];
    [propertyTable setHeaderView:tableHeaderView];
    [propertyTable setCornerView:nil];
    [tableHeaderView release];
    
    tableHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 120, 30)];
    [connectedApiTable setHeaderView:tableHeaderView];
    [connectedApiTable setCornerView:nil];
    [tableHeaderView release];
    
    for (NSTableColumn *column in [propertyTable tableColumns])
    {
        PATableHeaderCellView *cell = [[[PATableHeaderCellView alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
    
    for (NSTableColumn *column in [connectedApiTable tableColumns])
    {
        PATableHeaderCellView *cell = [[[PATableHeaderCellView alloc]init] autorelease];
        cell.stringValue = [[column headerCell] stringValue];
        
        [column setHeaderCell:cell];
    }
    
    self.connectedApis = [NSMutableArray arrayWithCapacity:10];
    [basicInfoView reloadObject:self.bean];
    beanName.item = self.bean;
    beanName.propertyKey = @"beanName";
    
    [propertyTable setDoubleAction:@selector(editPropertyAction:)];
    [propertyTable setTarget:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(valueExistsNotification:) name:PANOTIFICATION_OBJECT_VALUE_EXISTS object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(beanChildrenChanged:)
                                                 name:PANOTIFICATION_BEAN_CHILDREN_CHANGED
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectBeanChanged:) name:PANOTIFICATION_PROJECT_BEANS_CHANGED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectBeanChanged:) name:PANOTIFICATION_PROJECT_MAPPING_CHANGED object:nil];
    [self reloadConnectedApis];
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

-(void)reloadBean:(PABean*)newBean
{
//    [[GlobalSetting undoManager] removeAllActionsWithTarget:self];
    if (bean) {
//        [[GlobalSetting undoManager] removeAllActionsWithTarget:bean];
    }
    
    self.bean = newBean;
    [basicInfoView reloadObject:newBean];
    
    [self reloadConnectedApis];
    
}

-(void)reloadFieldItems
{
//    beanName.item = self.bean;
//    
//    beanName.propertyKey = @"beanName";
}

-(IBAction)editAction:(id)sender
{
    NSButton *btn = (NSButton*)sender;
    
    //add
    if (btn.tag == 1)
    {
        PAProperty *p = [bean defaultProperty];
        p.rowIndex = self.bean.properties.count;
        p.parentBean = self.bean;
        
        [self.bean insertProperties:[NSArray arrayWithObject:p]];
        PABean *b = self.bean;
        self.bean = nil;
        self.bean = b;
        
        [propertyTable selectRowIndexes:[NSIndexSet indexSetWithIndex:bean.properties.count-1] byExtendingSelection:NO];
        [self editPropertyAction:nil];
        
//        [propertyTable setNeedsDisplay];
        
//        [self addProperty:p forTable:propertyTable];
//        [propertyTable reloadData];
//        [propertyTable selectRowIndexes:[NSIndexSet indexSetWithIndex:bean.properties.count-1] byExtendingSelection:NO];
//        [self editPropertyAction:nil];
    }
    //remove properties
    else if (btn.tag == 2)
    {
        NSIndexSet *selectedIndexes = [propertyTable selectedRowIndexes];
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        
        [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [ma addObject:[bean.properties objectAtIndex:idx]];
        }];
        
        if (ma.count > 0)
        {
            [self.bean removeProperties:ma];
            [contents rearrangeObjects];
        }
    }
    //edit
    else if (btn.tag == 3)
    {
        [self editPropertyAction:nil];
    }
    //remove connection
    else if (btn.tag == 4)
    {
        NSUInteger selectedRow = [connectedApiTable selectedRow];
        NSString *k = [bean.mappings objectAtIndex:selectedRow];
        [bean.project removeMapping:k forBeanName:bean.beanName];
        
    }
}

-(IBAction)editPropertyAction:(id)sender
{
    NSInteger selectedRow = [propertyTable selectedRow];
    if (selectedRow != -1)
    {
        PAProperty *p = [bean.properties objectAtIndex:selectedRow];
        PropertyWindowController *pwc = [[PropertyWindowController alloc] initWithWindowNibName:@"PropertyWindowController"];
        self.editPropertyController = pwc;
        self.editPropertyController.proDelegate = self;
        if (!sender) {
            self.editPropertyController.firstEdit = YES;
        }
        [pwc release];
        
        [self.editPropertyController reloadProperty:p];
        self.editPropertyController.project = self.bean.project;
        [[NSApplication sharedApplication] runModalForWindow:self.editPropertyController.window];
    }
}

-(void)projectBeanChanged:(NSNotification*)notification
{
    [self reloadConnectedApis];
    [connectedApisArrayController rearrangeObjects];
}

-(void)beanChildrenChanged:(NSNotification*)notification
{
    PABean *b = self.bean;
    self.bean = nil;
    self.bean = b;
}

-(void)propertyEditDidFinished:(PropertyWindowController*)editController
{
    self.editPropertyController = nil;
}

-(void)valueExistsNotification:(NSNotification*)notification
{
    NSDictionary *dict = notification.object;
    NSString *object_type = [dict objectForKey:@"object_type"];
    NSString *key = [dict objectForKey:@"key"];
    NSString *value = [dict objectForKey:@"value"];
    id obj = [dict objectForKey:@"object"];
    
    if (obj != self.bean) {
        return;
    }
    
    if ([object_type isEqualToString:[PABean className]])
    {
        if ([key isEqualToString:@"beanName"])
        {
            beanName.stringValue = value;
            [beanName setNeedsDisplay];
        }
    }
}

-(void)reloadConnectedApis
{
    [self.connectedApis removeAllObjects];
    for (int i=0; i<bean.mappings.count; i++)
    {
        NSString *k = [bean.mappings objectAtIndex:i];
        NSArray *tmp = [k componentsSeparatedByString:@"/"];
        NSString *api_name = [tmp objectAtIndex:0];
        NSString *level = [k stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/",api_name] withString:@""];
        
        NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
        [md setObject:api_name forKey:@"apiName"];
        [md setObject:level forKey:@"level"];
        
        [self.connectedApis addObject:md];
    }
//    for (NSString *k in [bean.project.mapping.beanMapping allKeys]) {
//        NSString *v = [bean.project.mapping.beanMapping objectForKey:k];
//        
//        if ([v isEqualToString:self.bean.beanName])
//        {
//            NSArray *tmp = [k componentsSeparatedByString:@"/"];
//            NSString *api_name = [tmp objectAtIndex:0];
//            NSString *level = [k stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/",api_name] withString:@""];
//            
//            NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
//            [md setObject:api_name forKey:@"apiName"];
//            [md setObject:level forKey:@"level"];
//            
//            [self.connectedApis addObject:md];
//        }
//    }
    
    [self.connectedApisArrayController rearrangeObjects];
//    [connectedApiTable reloadData];
}

-(IBAction)tabAction:(id)sender
{
    if (currentTabIndex == 0)
    {
        //change to project
        [beanView setHidden:NO];
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
        [beanView setHidden:YES];
        [basicInfoView setHidden:NO];
        currentTabIndex = 0;
        NSRect r = tabBtn.frame;
        r.origin.x = 158;
        tabBtn.frame = r;
        [tabBtn setTitle:@"Bean"];
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

-(IBAction)copy:(id)sender
{
    if (sender != propertyTable)
    {
        return ;
    }
    
    NSMutableString *ms = [NSMutableString stringWithCapacity:1000];
    NSMutableArray *ma = [NSMutableArray array];
    
    if (sender == propertyTable)
    {
        NSIndexSet *indexSet = propertyTable.selectedRowIndexes;
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PAParam *p = [bean.properties objectAtIndex:idx];
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
    if (sender != propertyTable)
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
    
    if (sender == propertyTable)
    {
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        if ([type isEqualToString:PAOBJECT_NAME_NEW_BEAN])
        {
            NSDictionary *dict = nil;
            
            if ([type isEqualToString:PAOBJECT_NAME_NEW_BEAN])
            {
                dict = [pstr JSONValue];
                if (![dict isKindOfClass:[NSDictionary class]])
                {
                    return ;
                }
                //remove all null string keys
                NSArray *keys = [dict allKeys];
                NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:dict];
                NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
                
                for (NSString *k in keys)
                {
                    id v = [dict objectForKey:k];
                    if ([v isKindOfClass:[NSString class]] || [v isKindOfClass:[NSNumber class]])
                    {
                        continue ;
                    }
                    [ma addObject:k];
                }
                
                [md removeObjectsForKeys:ma];
                dict = md;
            }
            
            NSUndoManager *undo = [GlobalSetting undoManager];
            [undo beginUndoGrouping];
            NSArray *keys = [[dict allKeys] sortedArrayUsingSelector:@selector(compare:)];
            for (int i=0; i<keys.count; i++)
            {
                NSString *k = [keys objectAtIndex:i];
                NSString *v = [dict objectForKey:k];
                BOOL exists = NO;
                for (int j=0; j<bean.properties.count; j++)
                {
                    PAProperty *p = [bean.properties objectAtIndex:j];
                    if ([p.fieldName isEqualToString:k]) {
                        exists = YES;
                        break;
                    }
                }
                
                if (exists) {
                    continue ;
                }
                
                PAProperty *p = [bean defaultProperty];
                p.name = [bean newPropertyValueByValue:k forKey:@"name" except:p];
                p.fieldName = [bean newPropertyValueByValue:k forKey:@"fieldName" except:p];
                p.fieldType = [v isKindOfClass:[NSString class]]?PAFIELD_TYPE_STRING:PAFIELD_TYPE_NUMBER;
                p.rowIndex = bean.properties.count+i;
                p.parentBean = bean;
                [ma addObject:p];
            }
            
            if (ma.count>0) {
                [bean insertProperties:ma];
            }
            [undo endUndoGrouping];
        }
        else if ([type isEqualToString:PAOBJECT_NAME_PROPERTY] ||
                 [type isEqualToString:PAOBJECT_NAME_PROPERTY_ARRAY])
        {
            NSArray *objs = [PAExportEngine arrayForJsonString:pstr type:type];
            for (int i=0; i<objs.count; i++)
            {
                PAProperty *p = [objs objectAtIndex:i];
                p.name = [bean newPropertyValueByValue:p.name forKey:@"name" except:p];
                p.fieldName = [bean newPropertyValueByValue:p.fieldName forKey:@"fieldName" except:p];
                p.rowIndex = bean.properties.count+i;
                p.parentBean = bean;
            }
            
            if (objs.count > 0) {
                [bean insertProperties:objs];
            }
        }
    }
}

-(IBAction)cut:(id)sender
{
    if (sender != propertyTable)
    {
        return ;
    }
    
    [self copy:sender];
    
    [self delete:sender];
}

-(IBAction)delete:(id)sender
{
    if (sender == propertyTable)
    {
        NSIndexSet *selectedIndexes = [propertyTable selectedRowIndexes];
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        
        [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [ma addObject:[bean.properties objectAtIndex:idx]];
        }];
        
        if (ma.count > 0)
        {
            [self.bean removeProperties:ma];
            [contents rearrangeObjects];
        }
    }
}
@end
