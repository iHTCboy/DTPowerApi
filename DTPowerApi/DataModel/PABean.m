//
//  PABean.m
//  PowerApi
//
//  Created by leks on 12-7-24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PABean.h"
#import "PAProperty.h"
#import "DTUtil.h"
#import "PAProject.h"
#import "Global.h"

@implementation PABean
@synthesize beanType;
@synthesize beanName;
@synthesize mappingKey;
@synthesize index;
@synthesize linkStatus;
@synthesize linkStatusDesc;
@synthesize properties;
@synthesize project;
@synthesize mappings;

-(void)dealloc
{
    [beanType release];
    [beanName release];
    [mappingKey release];
    [index release];
    [linkStatusDesc release];
    [properties release];
    [mappings release];
    [super dealloc];
}

-(id)init
{
    if (self = [super init]) 
    {
        self.type = PAOBJECT_NAME_BEAN;
        self.typeName = PAOBJECT_NAME_BEAN;
        self.desc = PAOBJECT_DESC_BEAN;
        self.linkStatus = PABEAN_LINK_STATUS_UNDEFINED;
        self.linkStatusDesc = [PABEAN_STATUS_DESCS objectAtIndex:linkStatus];
        self.beanName = @"";
        self.beanType = @"";
        self.mappingKey = @"";
        self.index = @"";
        self.properties = [NSMutableArray arrayWithCapacity:10];
        self.mappings = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

-(NSDictionary*)toDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    [md setDictionary:[super toDict]];
    
    DICT_EXPORT1(beanType);
    DICT_EXPORT1(beanName);
    DICT_EXPORT1(mappingKey);
    DICT_EXPORT1(index);
    NSString *status = [NSString stringWithFormat:@"%ld", self.linkStatus];
    DICT_EXPORT3(status, md, @"linkStatus");
    DICT_EXPORT1(linkStatusDesc);
    
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
    for (int i=0; i<properties.count; i++)
    {
        PAProperty *property = [properties objectAtIndex:i];
        [ma addObject:[property toDict]];
    }
    
    [md setObject:ma forKey:@"properties"];
    
    [md setObject:self.mappings forKey:@"mappings"];
    return md;
}

-(NSDictionary*)copyDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    [md setDictionary:[super toDict]];
    
    DICT_EXPORT1(beanType);
    DICT_EXPORT1(beanName);
    DICT_EXPORT1(mappingKey);
    DICT_EXPORT1(index);
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
    for (int i=0; i<properties.count; i++)
    {
        PAProperty *property = [properties objectAtIndex:i];
        [ma addObject:[property toDict]];
    }
    
    [md setObject:ma forKey:@"properties"];
    
    return md;
}

-(id)initWithDict:(NSDictionary*)dict
{
    if (self = [super initWithDict:dict])
    {
        self.type = PAOBJECT_NAME_BEAN;
        self.typeName = PAOBJECT_NAME_BEAN;
        self.desc = PAOBJECT_DESC_BEAN;
        
        DICT_ASSIGN1(beanType);
        DICT_ASSIGN1(beanName);
        DICT_ASSIGN1(mappingKey);
        DICT_ASSIGN1(index);
        DICT_ASSIGN1(linkStatusDesc);
        

        self.linkStatus = [[dict objectForKey:@"linkStatus"] intValue];
        
        NSArray *tmpFields = [dict objectForKey:@"properties"];
        
        self.properties = [NSMutableArray arrayWithCapacity:10];
        for (int i=0; i<tmpFields.count; i++)
        {
            NSDictionary *tmpField = [tmpFields objectAtIndex:i];
            PAProperty *property = [[PAProperty alloc] initWithDict:tmpField];
            property.parentBean = self;
            property.rowIndex = i;
            [self.properties addObject:property];
            [property release];
        }
        
        self.mappings = [NSMutableArray arrayWithCapacity:10];
        NSArray *tmpMappings = [dict objectForKey:@"mappings"];
        if (tmpMappings.count > 0)
        {
            for (int i=0; i<tmpMappings.count; i++)
            {
                NSString *incomeMapping = [tmpMappings objectAtIndex:i];
                BOOL exists;
                for (int j=0; j<self.mappings.count; j++)
                {
                    NSString *existMapping = [self.mappings objectAtIndex:j];
                    if ([incomeMapping isEqualToString:existMapping])
                    {
                        exists = YES;
                    }
                }
                if (!exists) {
                    [self.mappings addObject:incomeMapping];
                }
            }
        }
    }
    
    return self;
}

-(void)setValue:(id)value forKey:(NSString *)key
{
    if ([key isEqualToString:@"name"] ||
        [key isEqualToString:@"beanName"])
    {
        BOOL exists = [PAObject object:self ValueExists:value forKey:key existsObjects:project.beans.allChildren];
        if (!exists && [self validateBeanName:value])
        {
            if ([key isEqualToString:@"beanName"])
            {
                [project bean:self name:self.beanName changeTo:value];
            }
            [super setValue:value forKey:key]; 
        }
        else
        {
            NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
            [md setObject:[self className] forKey:@"object_type"];
            [md setObject:key forKey:@"key"];
            [md setObject:[self valueForKey:key] forKey:@"value"];
            [md setObject:self forKey:@"object"];
            
            if (![self validateBeanName:value])
            {
                if ([key isEqualToString:@"name"])
                {
                    [md setObject:@"Bean name can not be empty!" forKey:@"msg"];
                }
                else if ([key isEqualToString:@"beanName"])
                {
                    [md setObject:@"Class name can not be empty!" forKey:@"msg"];
                }
            }
            else
            {
                if ([key isEqualToString:@"name"])
                {
                    [md setObject:@"Bean name already exists!" forKey:@"msg"];
                }
                else if ([key isEqualToString:@"beanName"])
                {
                    [md setObject:@"Class name already exists!" forKey:@"msg"];
                }
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_OBJECT_VALUE_EXISTS object:md];
        }
    }
    else
    {
        [super setValue:value forKey:key];
    }
}

-(BOOL)validateBeanName:(NSString*)beanname
{
    if (!beanname) {
        return NO;
    }
    return YES;
    
    NSString *regex = @"([a-zA-Z\\_]1)([a-zA-Z0-9\\_]*)";
    NSPredicate *urlPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    BOOL result = [urlPredicate evaluateWithObject:beanname];
    return result;
}

-(PAProperty*)defaultProperty
{
    PAProperty *property = [[PAProperty alloc] init];
    property.name = [self newPropertyValueByValue:@"Property" forKey:@"name" except:nil];
    property.fieldName = [self newPropertyValueByValue:@"Variable" forKey:@"fieldName" except:nil];
    property.fieldType = PAFIELD_TYPE_STRING;
    property.parentBean = self;
    return [property autorelease];
}

-(id)copyWithZone:(NSZone *)zone
{
    PABean *bean = [super copyWithZone:zone];
    if (bean) {
        bean.beanType = self.beanType;
        bean.beanName = self.beanName;
        bean.mappingKey = self.mappingKey;
        bean.index = self.index;
        bean.linkStatus = self.linkStatus;
        bean.linkStatusDesc = self.linkStatusDesc;
        
        bean.properties = [[[NSMutableArray alloc] initWithArray:self.properties copyItems:YES] autorelease];
    }
    
    return bean;
}

-(PAProperty*)addPropertyByField:(PAField*)field
{
    PAProperty *property = [[PAProperty alloc] init];
    property.name = [self newPropertyValueByValue:field.fieldName forKey:@"name" except:nil];
    property.fieldName = [self newPropertyValueByValue:field.fieldName forKey:@"fieldName" except:nil];
    property.fieldType = field.fieldType;
    property.mappingKey = field.mappingKey;
    property.parentMappingKey = field.parentMappingKey;
    property.beanName = field.beanName;
    property.rowIndex = self.properties.count;
    property.fromProperty = YES;
    property.defaultValue = @"";
    
//    [self.properties addObject:property];
    [self insertProperties:[NSArray arrayWithObject:property]];
    return [property autorelease];
//    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
//                          array, @"properties",
//                          @"insert", @"operation",
//                          [NSIndexSet indexSetWithIndex:property.rowIndex], @"indexSet", nil];
//    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_BEAN_CHILDREN_CHANGED object:dict];
}

-(BOOL)hasPropertyField:(PAField*)field
{
    for (int i=0; i<self.properties.count; i++)
    {
        PAProperty *property = [self.properties objectAtIndex:i];
        if ([property.fieldName isEqualToString:field.fieldName])
        {
            return YES;
        }
    }
    return NO;
}

-(NSString*)newPropertyValueByValue:(NSString*)value forKey:(NSString*)key except:(PAProperty*)eproperty
{
    return [PAObject object:eproperty valueByValue:value forKey:key existsObjects:self.properties];
//    NSMutableString *ms = [NSMutableString stringWithString:value];
//    int i=1;
//    while ([self propertyValueExists:ms forKey:key])
//    {
//        [ms setString:[NSString stringWithFormat:@"%@_%d", value, i]];
//        i++;
//    }
//    return ms;
}

-(BOOL)propertyValueExists:(NSString*)value forKey:(NSString*)key
{
    for (int i=0; i<self.properties.count; i++)
    {
        PAProperty *property = [self.properties objectAtIndex:i];
        NSString *pvalue = [property valueForKey:key];
        
        if ([value isEqualToString:pvalue])
        {
            return YES;
        }
    }
    return NO;
}

-(void)insertProperties:(NSArray *)array
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:10];
    [tmp setArray:self.properties];
    
    for (int i=0; i<array.count; i++)
    {
        PAProperty *p = [array objectAtIndex:i];
        if (p.rowIndex > tmp.count) {
            [indexSet addIndex:tmp.count];
        }
        else
        {
            [indexSet addIndex:p.rowIndex];
        }
        p.name = [PAObject object:p valueByValue:p.name forKey:@"name" existsObjects:tmp];
        p.fieldName = [PAObject object:p valueByValue:p.fieldName forKey:@"fieldName" existsObjects:tmp];
        p.parentBean = self;
        [tmp addObject:p];
    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeProperties:array];
    [self.properties insertObjects:array atIndexes:indexSet];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          array, @"properties",
                          @"insert", @"operation",
                          indexSet, @"indexSet", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_BEAN_CHILDREN_CHANGED object:dict];
}

-(void)removeProperties:(NSArray *)array
{
    NSIndexSet *indexSet = [PAObject indexesForObjects:array inArray:self.properties];
//    for (int i=0; i<array.count; i++)
//    {
//        PAProperty *p = [array objectAtIndex:i];
//        [indexSet addIndex:p.rowIndex];
//    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] insertProperties:array];
    [self.properties removeObjectsAtIndexes:indexSet];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          array, @"properties",
                          @"remove", @"operation",
                          indexSet, @"indexSet", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_BEAN_CHILDREN_CHANGED object:dict];
}

-(void)addMappingKey:(NSString*)k
{
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeMappingKey:k];
    
    for (int i=0; i<self.mappings.count; i++)
    {
        NSString *mk = [self.mappings objectAtIndex:i];
        if ([mk isEqualToString:k]) {
            return ;
        }
    }
    
    [self.mappings addObject:k];
}

-(void)removeMappingKey:(NSString*)k
{
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] addMappingKey:k];
    
    NSMutableIndexSet *mindexSet = [NSMutableIndexSet indexSet];
    
    for (int i=0; i<self.mappings.count; i++)
    {
        NSString *mk = [self.mappings objectAtIndex:i];
        if ([mk isEqualToString:k]) {
            [mindexSet addIndex:i];
//            [self.mappings removeObjectAtIndex:i];
            break;
        }
    }
    
    [self.mappings removeObjectsAtIndexes:mindexSet];
}
@end
