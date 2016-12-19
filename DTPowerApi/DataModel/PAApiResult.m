//
//  PAApiResult.m
//  DTPowerApi
//
//  Created by leks on 13-2-27.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAApiResult.h"
#import "DTUtil.h"

@implementation PAApiResult
@synthesize dateline;
@synthesize dateString;
@synthesize processTime;
@synthesize responseJsonString;
//@synthesize responseSrcString;
@synthesize responseHeaderString;
@synthesize expandedItems;
@synthesize lastResultYOffset;
@synthesize isLocal;
@synthesize parentApi;
@synthesize groupName;
@synthesize sentSize;
@synthesize receivedSize;
@synthesize processString;
@synthesize responseStatus;
@synthesize responseHeaders;
@synthesize responseString;

-(void)dealloc
{
    [dateline release];
    [dateString release];
    [processTime release];
    [responseJsonString release];
//    [responseSrcString release];
    [responseHeaderString release];
    [expandedItems release];
    [lastResultYOffset release];
    [groupName release];
    [sentSize release];
    [receivedSize release];
    [processString release];
    
    [responseStatus release];
    [responseHeaders release];
    [responseString release];
    [super dealloc];
}

-(id)init
{
    if (self = [super init])
    {
        self.type = PAOBJECT_NAME_APIRESULT;
        self.typeName = PAOBJECT_NAME_APIRESULT;
//        self.responseSrcString = @"";
        self.responseJsonString = @"";
        self.responseHeaderString = @"";
        self.responseStatus = @"";
        self.responseHeaders = @"";
        self.responseString = @"";
        
        self.expandedItems = [NSMutableArray arrayWithCapacity:10];
    }
    
    return self;
}

-(NSDictionary*)toDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    [md setDictionary:[super toDict]];
    
    DICT_EXPORT1(dateline);
    DICT_EXPORT1(dateString);
    DICT_EXPORT1(processTime);
    DICT_EXPORT1(processString);
    DICT_EXPORT1(responseJsonString);
//    DICT_EXPORT1(responseSrcString);
    DICT_EXPORT1(responseHeaderString);
    DICT_EXPORT1(lastResultYOffset);
    DICT_EXPORT1(groupName);
    DICT_EXPORT1(sentSize);
    DICT_EXPORT1(receivedSize);
    DICT_EXPORT1(responseStatus);
    DICT_EXPORT1(responseHeaders);
    DICT_EXPORT1(responseString);
    
    if (isLocal) {
        [md setObject:@"1" forKey:@"isLocal"];
    }
    else
    {
        [md setObject:@"0" forKey:@"isLocal"];
    }
    
    [md setObject:expandedItems forKey:@"expandedItems"];
    return md;
}

-(id)initWithDict:(NSDictionary*)dict
{
    if (self = [super initWithDict:dict])
    {
        self.type = PAOBJECT_NAME_APIRESULT;
        self.typeName = PAOBJECT_NAME_APIRESULT;
        self.expandedItems = [NSMutableArray arrayWithCapacity:10];
        
        DICT_ASSIGN1(dateline);
        DICT_ASSIGN1(dateString);
        DICT_ASSIGN1(processTime);
        DICT_ASSIGN1(processString);
        DICT_ASSIGN1(responseJsonString);
//        DICT_ASSIGN1(responseSrcString);
        DICT_ASSIGN1(responseHeaderString);
        DICT_ASSIGN1(lastResultYOffset);
        DICT_ASSIGN1(groupName);
        DICT_ASSIGN1(sentSize);
        DICT_ASSIGN1(receivedSize);
        DICT_ASSIGN1(responseStatus);
        DICT_ASSIGN1(responseHeaders);
        DICT_ASSIGN1(responseString);
        
        id exItems = [dict objectForKey:@"expandedItems"];
        if ([exItems isKindOfClass:[NSArray class]])
        {
            [self.expandedItems setArray:exItems];
        }
        
        NSString *ilocal = [dict objectForKey:@"isLocal"];
        if (ilocal.integerValue == 1) {
            self.isLocal = YES;
        }
        else
        {
            self.isLocal = NO;
        }
    }
    
    return self;
}

-(void)start
{
    [self.expandedItems removeAllObjects];
    self.lastResultYOffset = @"0";
    self.dateline = [NSString stringWithFormat:@"%.3lf", [[NSDate date] timeIntervalSince1970]];
    self.dateString = [DTUtil timeIntervalSince1970:self.dateline.doubleValue Format:@"yyyy-MM-dd HH:mm"];
}

-(void)stop
{
    NSTimeInterval ti = [[NSDate date] timeIntervalSince1970];
    self.processTime = [NSString stringWithFormat:@"%.3lf", ti - self.dateline.doubleValue];
    self.processString = [NSString stringWithFormat:@"%.3lfs", self.processTime.doubleValue];
}

-(void)resetAsLocal
{
    self.isLocal = YES;
    [self start];
    [self stop];
    self.processTime = @"N/A";
    self.processString = @"N/A";
    self.groupName = @"N/A";
}
@end
