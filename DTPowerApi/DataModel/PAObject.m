//
//  PAObject.m
//  PowerApi
//
//  Created by leks on 12-7-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PAObject.h"
#import "DTUtil.h"
#import "JSON.h"
#import "Global.h"

@implementation PAObject
@synthesize oid;
@synthesize name;
@synthesize desc;
@synthesize comment;
@synthesize type;
@synthesize typeName;
@synthesize rowIndex;
@synthesize expanded;

-(id)init
{
    if (self = [super init]) {
        rowIndex = -1;
        self.oid = @"";
        self.name = @"";
        self.desc = @"";
        self.comment = @"";
        self.type = @"";
        self.typeName = @"";
    }
    return self;
}

-(void)dealloc
{
    [oid release];
    [name release];
    [desc release];
    [comment release];
    [type release];
    [typeName release];
    [super dealloc];
}

-(NSDictionary*)toDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    DICT_EXPORT1(oid);
    DICT_EXPORT1(name);
//    DICT_EXPORT1(desc);
    DICT_EXPORT1(comment);
    DICT_EXPORT1(type);
//    DICT_EXPORT1(typeName);
    if (expanded) {
        [md setObject:@"1" forKey:@"expanded"];
    }
    else
    {
        [md setObject:@"0" forKey:@"expanded"];
    }
    
    [md setObject:self.type forKey:PAOBJECT_SOURCE_TYPE];

    return md;
}

-(NSString*)dictString
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    [md setDictionary:[self toDict]];
    [md setObject:self.type forKey:PAOBJECT_SOURCE_TYPE];
    
    return [md JSONRepresentation];
}

-(id)initWithDict:(NSDictionary*)dict
{
    if (self = [self init])
    {
        DICT_ASSIGN1(oid);
        DICT_ASSIGN1(name);
//        DICT_ASSIGN1(desc);
        DICT_ASSIGN1(comment);
//        DICT_ASSIGN1(type);
//        DICT_ASSIGN1(typeName);
        NSString *exped = [dict objectForKey:@"expanded"];
        if (exped.integerValue == 1) {
            expanded = YES;
        }
        else
        {
            expanded = NO;
        }
    }
    
    return self;
}

//- (void)setItemProperty:(NSString*)property withValue:(NSString*)value
//{
//    NSString *rm = [self valueForKey:property];
//    NSString *pvalue = nil;
//    if (rm) {
//        pvalue = [NSString stringWithString:rm];
//    }
//    
//    if (pvalue && ![pvalue isEqualToString:value])
//    {
//        [[undoManager prepareWithInvocationTarget:self] setItemProperty:property withValue:pvalue];
//        [self setValue:value forKey:property];
//    }
//}

-(void)setValue:(id)value forKey:(NSString *)key
{
    NSString *rm = [self valueForKey:key];
    id pvalue = @"";
    if (rm) {
        pvalue = [NSString stringWithString:rm];
    }

    NSUndoManager *undoManager = [GlobalSetting undoManager];
    if (pvalue && ![pvalue isEqualToString:value])
    {
        gNeedSave = YES;
        [[undoManager prepareWithInvocationTarget:self] setValue:pvalue forKey:key];
        [super setValue:value forKey:key];
        //notify ui change
        [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_OBJECT_VALUE_CHANGED object:[self className]];
    }
    else if ([pvalue isEqualToString:value])
    {
//        [super setValue:value forKey:key];
    }
    
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"typeName:%@\nname:%@\ndesc:%@\ncomment:%@\n", typeName, name, desc, comment];
}

- (id)copyWithZone:(NSZone *)zone
{
    PAObject *obj = [[[self class] allocWithZone:zone] init];
    if (obj) {
        obj.name = self.name;
        obj.oid = self.oid;
        obj.desc = self.desc;
        obj.comment = self.comment;
        obj.type = self.type;
        obj.typeName = self.typeName;
    }
    return obj;//[obj autorelease];
}

/////////////////////////////
/////////////////////////////
+(NSString*)object:(NSObject*)object valueByValue:(NSString*)value forKey:(NSString*)key existsObjects:(NSArray*)earray
{
    NSMutableString *ms = [NSMutableString stringWithString:value];
    int i=1;
    while ([PAObject object:object ValueExists:ms forKey:key existsObjects:earray])
    {
        [ms setString:[NSString stringWithFormat:@"%@_%d", value, i]];
        i++;
    }
    return ms;
}

+(BOOL)object:(NSObject*)object ValueExists:(NSString*)value forKey:(NSString*)key existsObjects:(NSArray*)earray
{
    for (int i=0; i<earray.count; i++)
    {
        NSObject *obj = [earray objectAtIndex:i];
        if (object == obj) {
            continue ;
        }
        NSString *pvalue = [obj valueForKey:key];
        
        if ([value isEqualToString:pvalue])
        {
            return YES;
        }
    }
    
    return NO;
}

+(NSIndexSet*)indexesForObjects:(NSArray*)objects inArray:(NSArray*)array
{
    NSMutableIndexSet *mindexSet = [NSMutableIndexSet indexSet];
    for (int i=0; i<objects.count; i++)
    {
        id obj = [objects objectAtIndex:i];
        for (int j=0; j<array.count; j++)
        {
            id obj2 = [array objectAtIndex:j];
            if (obj == obj2) {
                [mindexSet addIndex:j];
                break;
            }
        }
    }
    
    return mindexSet;
}
@end
