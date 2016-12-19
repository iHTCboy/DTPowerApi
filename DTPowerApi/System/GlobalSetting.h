//
//  GlobalSetting.h
//  DTPowerApi
//
//  Created by leks on 13-1-18.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PAImage.h"

@class PAProject;

@interface GlobalSetting : NSObject
{
    NSMutableArray *expandedItems;
    NSString *lastResultYOffset;
    
    NSImage *tableHeaderBgImage;
    NSImage *tableRowBgImage;
    NSImage *tableRowHighlightedBgImage;
    NSImage *tableGridVerticalImage;
    NSImage *tableGridHorizontalImage;
    
    NSImage *datamappingTableRowBgImage1;
    NSImage *datamappingTableRowBgImage2;
    
    
}

@property (nonatomic, retain) NSMutableArray *expandedItems;
@property (nonatomic, retain) NSString *lastResultYOffset;
@property (nonatomic, retain) NSImage *tableHeaderBgImage;
@property (nonatomic, retain) NSImage *tableRowBgImage;
@property (nonatomic, retain) NSImage *tableRowHighlightedBgImage;
@property (nonatomic, retain) NSImage *tableGridVerticalImage;
@property (nonatomic, retain) NSImage *tableGridHorizontalImage;
@property (nonatomic, retain) NSImage *datamappingTableRowBgImage1;
@property (nonatomic, retain) NSImage *datamappingTableRowBgImage2;

-(void)reloadWithDict:(NSDictionary*)dict;
-(id)initWithDict:(NSDictionary*)dict;
-(NSDictionary*)toDict;
+(NSUndoManager*)undoManager;

+(NSString*)helloworldProjectString;
+(PAProject*)helloworldProject;
@end
