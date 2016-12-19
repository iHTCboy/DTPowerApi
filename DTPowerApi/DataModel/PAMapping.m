//
//  PAMapping.m
//  DTPowerApi
//
//  Created by leks on 13-1-25.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAMapping.h"

@implementation PAMapping
@synthesize beanMapping;

-(void)dealloc
{
    [beanMapping release];
    [super dealloc];
}

-(id)init
{
    if (self = [super init]) {
        self.beanMapping = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

-(id)initWithDict:(NSDictionary *)dict
{
    if (self = [super initWithDict:dict])
    {
        NSDictionary *tmp = [dict objectForKey:@"beanMapping"];
        self.beanMapping = [NSMutableDictionary dictionaryWithCapacity:10];
        if (tmp.count > 0) {
            [self.beanMapping setDictionary:tmp];
        }
    }
    
    return self;
}

-(NSDictionary*)toDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    [md setObject:self.beanMapping forKey:@"beanMapping"];
    return md;
}
@end
