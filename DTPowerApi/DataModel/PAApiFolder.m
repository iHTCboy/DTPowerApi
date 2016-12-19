//
//  PAApiFolder.m
//  DTPowerApi
//
//  Created by leks on 13-1-4.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAApiFolder.h"
#import "PAApi.h"
#import "DTUtil.h"
#import "PAProject.h"

@implementation PAApiFolder
@synthesize children;
@synthesize allChildren;
@synthesize project;
@synthesize filterKeyword;

-(void)dealloc
{
    [children release];
    [allChildren release];
    [filterKeyword release];
    [super dealloc];
}

-(id)init
{
    if (self = [super init]) {
        self.type = PAOBJECT_NAME_APIFOLDER;
        self.typeName = PAOBJECT_NAME_APIFOLDER;
        self.desc = PAOBJECT_DESC_APIFOLDER;
        self.children = [NSMutableArray arrayWithCapacity:10];
        self.allChildren = [NSMutableArray arrayWithCapacity:10];
        self.filterKeyword = @"";
    }
    
    return self;
}

-(NSDictionary*)toDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    [md setDictionary:[super toDict]];
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
    for (int i=0; i<allChildren.count; i++)
    {
        PAApi *api = [allChildren objectAtIndex:i];
        [ma addObject:[api toDict]];
    }
    
    [md setObject:ma forKey:@"children"];
    
    return md;
}

-(id)initWithDict:(NSDictionary*)dict
{
    if (self = [super initWithDict:dict])
    {
        NSArray *tmpChildren = [dict objectForKey:@"children"];
        
        self.children = [NSMutableArray arrayWithCapacity:10];
        self.allChildren = [NSMutableArray arrayWithCapacity:10];
        for (int i=0; i<tmpChildren.count; i++)
        {
            NSDictionary *tmpApi = [tmpChildren objectAtIndex:i];
            PAApi *api = [[PAApi alloc] initWithDict:tmpApi];
            api.rowIndex = i;
            [self.allChildren addObject:api];
            [api release];
        }
        
        [self.children setArray:self.allChildren];
    }

    return self;
}

-(void)filterChildren:(NSString*)keyword
{
    @synchronized(self)
    {
        self.filterKeyword = keyword;
        [self.children removeAllObjects];
        for (int i=0; i<self.allChildren.count; i++)
        {
            PAApi *api = [self.allChildren objectAtIndex:i];
            if (keyword.length == 0 ||
                [[api.name lowercaseString] rangeOfString:keyword].length > 0)
            {
                [self.children addObject:api];
            }
        }
    }
}

-(void)refilterChildren
{
    @synchronized(self)
    {
        [self.children removeAllObjects];
        for (int i=0; i<self.allChildren.count; i++)
        {
            PAApi *api = [self.allChildren objectAtIndex:i];
            if (self.filterKeyword.length == 0 ||
                [[api.name lowercaseString] rangeOfString:self.filterKeyword].length > 0)
            {
                [self.children addObject:api];
            }
        }
    }
}

-(PAApi*)defaultApi
{
    PAApi *api = [[PAApi alloc] init];
    api.name = [project api:api valueByValue:@"Api" forKey:@"name"];
    api.url = @"${PROJECT_BASEURL}";

    return [api autorelease];
}

-(id)copyWithZone:(NSZone *)zone
{
    PAApiFolder *apiFolder = [super copyWithZone:zone];
    if (apiFolder) {
        apiFolder.allChildren = [[[NSMutableArray alloc] initWithArray:self.allChildren copyItems:YES] autorelease];
        apiFolder.children = [[[NSMutableArray alloc] initWithArray:self.children copyItems:YES] autorelease];
    }
    
    return apiFolder;
}

-(void)refreshApiIndexes
{
    for (int i=0; i<allChildren.count; i++)
    {
        PAApi *a = [allChildren objectAtIndex:i];
        a.rowIndex = i;
    }
}


@end
