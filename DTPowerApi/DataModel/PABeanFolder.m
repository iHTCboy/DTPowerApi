//
//  PABeanFolder.m
//  DTPowerApi
//
//  Created by leks on 13-1-4.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PABeanFolder.h"
#import "PABean.h"
#import "PAProject.h"
#import "Global.h"

@implementation PABeanFolder
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
        self.type = PAOBJECT_NAME_BEANFOLDER;
        self.typeName = PAOBJECT_NAME_BEANFOLDER;
        self.desc = PAOBJECT_DESC_BEANFOLDER;
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
        PABean *bean = [allChildren objectAtIndex:i];
        [ma addObject:[bean toDict]];
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
            NSDictionary *tmpBean = [tmpChildren objectAtIndex:i];
            PABean *bean = [[PABean alloc] initWithDict:tmpBean];
            bean.rowIndex = i;
            [self.allChildren addObject:bean];
            [bean release];
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
            PABean *bean = [self.allChildren objectAtIndex:i];
            if (keyword.length == 0 ||
                [[bean.name lowercaseString] rangeOfString:keyword].length > 0)
            {
                [self.children addObject:bean];
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
            PABean *bean = [self.allChildren objectAtIndex:i];
            if (self.filterKeyword.length == 0 ||
                [[bean.name lowercaseString] rangeOfString:self.filterKeyword].length > 0)
            {
                [self.children addObject:bean];
            }
        }
    }
}

-(PABean*)defaultBean
{
    PABean *bean = [[PABean alloc] init];
    bean.name = [project bean:bean valueByValue:@"Bean" forKey:@"name"];
    bean.beanName = [project bean:bean valueByValue:@"Bean" forKey:@"beanName"];
    bean.beanType = @"Object";
    return [bean autorelease];
}

-(id)copyWithZone:(NSZone *)zone
{
    PABeanFolder *beanFolder = [super copyWithZone:zone];
    if (beanFolder) {
        beanFolder.allChildren = [[[NSMutableArray alloc] initWithArray:self.allChildren copyItems:YES] autorelease];
        beanFolder.children = [[[NSMutableArray alloc] initWithArray:self.children copyItems:YES] autorelease];
    }
    
    return beanFolder;
}

-(void)refreshBeanIndexes
{
    for (int i=0; i<allChildren.count; i++)
    {
        PABean *b = [allChildren objectAtIndex:i];
        b.rowIndex = i;
    }
}
@end
