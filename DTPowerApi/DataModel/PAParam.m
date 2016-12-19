//
//  PAParam.m
//  PowerApi
//
//  Created by leks on 12-7-24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PAParam.h"
#import "DTUtil.h"
#import "PAParamGroup.h"

@implementation PAParam
@synthesize paramType;
@synthesize paramKey;
@synthesize filename;

@synthesize paramValue;
@synthesize method;
@synthesize contentType;
@synthesize parentGroup;

-(void)dealloc
{
    [paramType release];
    [paramKey release];
    [filename release];
    [paramValue release];
    [method release];
    [contentType release];
    [super dealloc];
}

-(id)init
{
    if (self = [super init]) 
    {
        self.type = PAOBJECT_NAME_PARAM;
        self.typeName = PAOBJECT_NAME_PARAM;
        self.desc = PAOBJECT_DESC_PARAM;
        self.paramKey = @"";
        self.paramType = PAPARAM_TYPE_STRING;
        self.filename = @"";
        self.paramValue = @"";
        self.method = @"";
        self.contentType = @"Auto";
    }
    return self;
}

-(NSDictionary*)toDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    [md setDictionary:[super toDict]];
    
    DICT_EXPORT1(paramKey);
    DICT_EXPORT1(paramType);
    DICT_EXPORT1(filename);
    DICT_EXPORT1(method);
    DICT_EXPORT1(contentType);
    
    if ([paramType isEqualToString:PAPARAM_TYPE_STRING] ||
        [paramType isEqualToString:PAPARAM_TYPE_NUMBER])
    {
        DICT_EXPORT1(paramValue);
    }
    
    return md;
}

-(id)initWithDict:(NSDictionary*)dict
{
    if (self = [super initWithDict:dict])
    {
        self.type = PAOBJECT_NAME_PARAM;
        self.typeName = PAOBJECT_NAME_PARAM;
        self.desc = PAOBJECT_DESC_PARAM;
        
        DICT_ASSIGN1(paramKey);
        DICT_ASSIGN1(paramType);
        DICT_ASSIGN1(filename);
        DICT_ASSIGN1(method);
        DICT_ASSIGN1(contentType);
        
        if ([paramType isEqualToString:PAPARAM_TYPE_STRING] ||
            [paramType isEqualToString:PAPARAM_TYPE_NUMBER])
        {
            DICT_ASSIGN1(paramValue);
        }
    }
    
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    PAParam *param = [super copyWithZone:zone];
    if (param) {
        param.paramType = self.paramType;
        param.paramKey = self.paramKey;
        param.filename = self.filename;
        param.method = self.method;
        param.paramValue = self.paramValue;
        param.contentType = self.contentType;
        param.parentGroup = self.parentGroup;
    }
    return param;
}

-(void)setValue:(id)value forKey:(NSString *)key
{
    if ([key isEqualToString:@"paramKey"] ||
        [key isEqualToString:@"name"])
    {
        BOOL isPost = NO;
        if ([self.method isEqualToString:PAPARAM_METHOD_POST])
        {
            isPost = YES;
        }
        BOOL exists = [parentGroup paramValueExists:value forKey:key isPost:isPost];
        if (!exists) {
            [super setValue:value forKey:key];
        }
        else
        {
            NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
            [md setObject:[self className] forKey:@"object_type"];
            [md setObject:key forKey:@"key"];
            [md setObject:[self valueForKey:key] forKey:@"value"];
            [md setObject:self forKey:@"object"];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_OBJECT_VALUE_EXISTS object:md];
        }
    }
    else
    {
        [super setValue:value forKey:key];
    }
}

+(NSDictionary*)parseUrlString:(NSString*)url
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    NSMutableString *ms = [NSMutableString stringWithCapacity:10];
    
    if ([DTUtil isHttpURL:url])
    {
        NSArray *tmp = [url componentsSeparatedByString:@"?"];
        if (tmp.count <= 1)
        {
            return md;
        }
        else
        {
            for (int i=1; i<tmp.count; i++)
            {
                [ms appendString:[tmp objectAtIndex:i]];
            }
        }
    }
    else
    {
        [ms setString:url];
    }
    
    NSArray *array = [ms componentsSeparatedByString:@"&"];
    NSMutableArray *allKeys = [NSMutableArray arrayWithCapacity:10];
    if (array.count > 0)
    {
        for (int i=0; i<array.count; i++)
        {
            NSString *pairString = [array objectAtIndex:i];
            NSArray *pair = [pairString componentsSeparatedByString:@"="];
            if (pair.count == 2) {
                [md setObject:[pair objectAtIndex:1] forKey:[pair objectAtIndex:0]];
                [allKeys addObject:[pair objectAtIndex:0]];
            };
        }
    }

    [md setObject:allKeys forKey:@"$$allkeys$$"];
    return md;
}
@end
