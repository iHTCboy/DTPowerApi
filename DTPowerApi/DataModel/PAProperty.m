//
//  PAField.m
//  PowerApi
//
//  Created by leks on 12-7-24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PAProperty.h"
#import "DTUtil.h"
#import "PABean.h"

@implementation PAProperty
@synthesize linkStatusDesc;
@synthesize defaultValue;
@synthesize parentBean;

-(void)dealloc
{
    [linkStatusDesc release];
    [defaultValue release];
    [super dealloc];
}

-(id)init
{
    if (self = [super init]) 
    {
        self.type = PAOBJECT_NAME_PROPERTY;
        self.typeName = PAOBJECT_NAME_PROPERTY;
        self.desc = self.desc = PAOBJECT_DESC_PROPERTY;
    }
    return self;
}

-(NSDictionary*)toDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    [md setDictionary:[super toDict]];
    
    return md;
}

-(id)initWithDict:(NSDictionary*)dict
{
    if (self = [super initWithDict:dict])
    {

    }
    
    return self;
}

-(void)setValue:(id)value forKey:(NSString *)key
{
    if ([key isEqualToString:@"fieldName"] ||
        [key isEqualToString:@"name"])
    {
        BOOL exists = [PAObject object:self ValueExists:value forKey:key existsObjects:parentBean.properties];//[parentBean propertyValueExists:value forKey:key];
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
@end
