//
//  GlobalSetting.m
//  DTPowerApi
//
//  Created by leks on 13-1-18.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "GlobalSetting.h"
#import "DTUtil.h"
#import "PAUndoManager.h"
#import "PAProject.h"
#import "JSON.h"

@implementation GlobalSetting
@synthesize expandedItems;
@synthesize lastResultYOffset;
@synthesize tableHeaderBgImage;
@synthesize tableRowBgImage;
@synthesize tableRowHighlightedBgImage;
@synthesize tableGridVerticalImage;
@synthesize tableGridHorizontalImage;
@synthesize datamappingTableRowBgImage1;
@synthesize datamappingTableRowBgImage2;

-(void)dealloc
{
    [tableHeaderBgImage release];
    [tableRowBgImage release];
    [tableRowHighlightedBgImage release];
    [tableGridHorizontalImage release];
    [tableGridVerticalImage release];
    [datamappingTableRowBgImage1 release];
    [datamappingTableRowBgImage2 release];
    [expandedItems release];
    [lastResultYOffset release];
    [super dealloc];
}

-(id)init
{
    if (self = [super init])
    {
        self.expandedItems = [NSMutableArray arrayWithCapacity:10];
        self.lastResultYOffset = @"0";
        self.tableHeaderBgImage = [NSImage imageNamed:@"table_header_bg"];
//        [self.tableHeaderBgImage sliceWidth:5 height:28];
        self.tableRowBgImage = [NSImage imageNamed:@"table_row_bg"];
        self.tableRowHighlightedBgImage = [NSImage imageNamed:@"table_row_highlighted"];
        self.tableGridVerticalImage = [NSImage imageNamed:@"table_grid_vertical"];
        self.tableGridHorizontalImage = [NSImage imageNamed:@"table_grid_horizontal"];
        self.datamappingTableRowBgImage1 = [NSImage imageNamed:@"datamapping_table_row_bg_1"];
        self.datamappingTableRowBgImage2 = [NSImage imageNamed:@"datamapping_table_row_bg_2"];
    }
    
    return self;
}

-(id)initWithDict:(NSDictionary*)dict
{
    if (self = [self init])
    {
        self.tableHeaderBgImage = [NSImage imageNamed:@"table_header_bg"];
//        [self.tableHeaderBgImage sliceWidth:5 height:28];
        self.tableRowBgImage = [NSImage imageNamed:@"table_row_bg"];
        self.tableRowHighlightedBgImage = [NSImage imageNamed:@"table_row_highlighted"];
        self.tableGridVerticalImage = [NSImage imageNamed:@"table_grid_vertical"];
        self.tableGridHorizontalImage = [NSImage imageNamed:@"table_grid_horizontal"];
        self.datamappingTableRowBgImage1 = [NSImage imageNamed:@"datamapping_table_row_bg_1"];
        self.datamappingTableRowBgImage2 = [NSImage imageNamed:@"datamapping_table_row_bg_2"];
        
        [self reloadWithDict:dict];
    }
    
    return self;
}

-(NSDictionary*)toDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    DICT_EXPORT1(lastResultYOffset);
    DICT_EXPORT1(expandedItems);
    
    return md;
}

-(void)reloadWithDict:(NSDictionary*)dict
{
    DICT_ASSIGN1(lastResultYOffset);
    
    id exItems = [dict objectForKey:@"expandedItems"];
    if ([exItems isKindOfClass:[NSArray class]])
    {
        [self.expandedItems setArray:exItems];
    }
}

+(NSUndoManager*)undoManager
{
    static NSUndoManager *undoManager = nil;
    if (!undoManager) {
        undoManager = [[PAUndoManager alloc] init];
//        [undoManager setGroupsByEvent:NO];
    }
    
    return undoManager;
}

+(NSString*)helloworldProjectString
{
    NSString *helloworldPath = [[NSBundle mainBundle] pathForResource:@"HelloworldProjectTemplate" ofType:@"strings"];
    NSMutableString *helloworldPathString = [NSMutableString stringWithContentsOfFile:helloworldPath encoding:NSUnicodeStringEncoding error:nil];
    
    return helloworldPathString;
}

+(PAProject*)helloworldProject
{
    NSDictionary *pjDict = [[GlobalSetting helloworldProjectString] JSONValue];
    if ([pjDict isKindOfClass:[NSDictionary class]])
    {
        PAProject *p = [[PAProject alloc] initWithDict:pjDict];
        return [p autorelease];
    }
    
    return nil;
}
@end
