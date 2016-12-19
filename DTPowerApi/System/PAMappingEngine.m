//
//  PAMappingEngine.m
//  DTPowerApi
//
//  Created by leks on 13-1-24.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAMappingEngine.h"
#import "JSON.h"
#import "PAProject.h"
#import "PABean.h"
#import "PAProperty.h"

#define PAMAPPING_ROOT_NAME @"_root_"

@interface PAMappingEngine(private)

+(PAField*)generateFieldByDictionary:(NSDictionary*)dict withFieldName:(NSString*)fieldName MappingKey:(NSString*)mappingKey parentMappingKey:(NSString*)parentMappingKey;

+(NSArray*)generateFieldsByArray:(NSArray*)array withFieldName:(NSString*)fieldName MappingKey:(NSString*)mappingKey parentMappingKey:(NSString*)parentMappingKey;

@end

@implementation PAMappingEngine


+(NSMutableArray*)generateFieldsByJsonString:(NSString*)jsonString forApi:(NSString*)apiName
{
    NSMutableArray *fields = [NSMutableArray arrayWithCapacity:10];
    id jsonObj = [jsonString JSONValue];
    if ([jsonObj isKindOfClass:[NSDictionary class]])
    {
        PAField *field = [PAMappingEngine generateFieldByDictionary:jsonObj
                                                      withFieldName:PAMAPPING_ROOT_NAME
                                                         MappingKey:[NSString stringWithFormat:@"%@/%@", apiName, PAMAPPING_ROOT_NAME]
                                                   parentMappingKey:nil];
        [fields addObject:field];
    }
    else if ([jsonObj isKindOfClass:[NSArray class]])
    {
        NSArray *array = [PAMappingEngine generateFieldsByArray:jsonObj
                                                  withFieldName:PAMAPPING_ROOT_NAME
                                                     MappingKey:[NSString stringWithFormat:@"%@/%@", apiName, PAMAPPING_ROOT_NAME]
                                               parentMappingKey:nil];
        [fields addObjectsFromArray:array];
    }
    
    return fields;
}

/*
 generate single field by dictionary object
 */
+(PAField*)generateFieldByDictionary:(NSDictionary*)dict withFieldName:(NSString*)fieldName MappingKey:(NSString*)mappingKey parentMappingKey:(NSString*)parentMappingKey
{
    PAField *parentField = [[PAField alloc] init];
    parentField.fieldName = fieldName;
    parentField.fieldType = PAFIELD_TYPE_OBJECT;
    parentField.fieldValue = @"";
    parentField.parentMappingKey = parentMappingKey;
    parentField.mappingKey = mappingKey;
    
    NSMutableArray *keys = [NSMutableArray arrayWithArray:[dict allKeys]];
    [keys sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for (NSString *k in keys)
    {
        id value = [dict objectForKey:k];
        
        if (!value) {
            continue ;
        }
        
        if ([value isKindOfClass:[NSDictionary class]])
        {
            NSString *mk = [NSString stringWithFormat:@"%@/%@", mappingKey, k];
            PAField *subField = [PAMappingEngine generateFieldByDictionary:value withFieldName:k MappingKey:mk parentMappingKey:mappingKey];
            subField.parentField = parentField;
            subField.fieldValue = @"";
            [parentField.subFields addObject:subField];
            continue ;
        }
        
        PAField *field = [[[PAField alloc] init] autorelease];
        field.fieldName = k;
        field.parentField = parentField;
        field.parentMappingKey = parentField.mappingKey;
        field.mappingKey = [NSString stringWithFormat:@"%@/%@", parentField.mappingKey, k];
        
        if ([value isKindOfClass:[NSNull class]])
        {
            field.fieldType = PAFIELD_TYPE_NULL;
            field.fieldValue = @"Null";
        }
        else if ([value isKindOfClass:[NSString class]])
        {
            field.fieldType = PAFIELD_TYPE_STRING;
            field.fieldValue = value;
        }
        else if ([value isKindOfClass:[NSNumber class]])
        {
            field.fieldType = PAFIELD_TYPE_NUMBER;
            field.fieldValue = [value stringValue];
        }
        else if ([value isKindOfClass:[NSArray class]])
        {
            field.fieldType = PAFIELD_TYPE_ARRAY;
            NSArray *subfields = [PAMappingEngine generateFieldsByArray:value withFieldName:k MappingKey:field.mappingKey parentMappingKey:field.parentMappingKey];
            
            for (int i=0;i<subfields.count; i++)
            {
                PAField *f = [subfields objectAtIndex:i];
                f.parentField = field;
            }
            [field.subFields addObjectsFromArray:subfields];
            field.fieldValue = @"";
        }
        
        [parentField.subFields addObject:field];
    }
    
    return [parentField autorelease];
}

/*
 generate list fields by Array object
 */
+(NSArray*)generateFieldsByArray:(NSArray*)array withFieldName:(NSString*)fieldName MappingKey:(NSString*)mappingKey parentMappingKey:(NSString*)parentMappingKey
{
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
    
    for (int i=0;i<array.count; i++)
    {
        PAField *field = nil;
        id value = [array objectAtIndex:i];
        NSString *fn = [NSString stringWithFormat:@"%@[%d]", fieldName, i];
        if (array.count >= 100) {
            fn = [NSString stringWithFormat:@"%@[%03d]", fieldName, i];
        }
        else if (array.count >= 10) {
            fn = [NSString stringWithFormat:@"%@[%02d]", fieldName, i];
        }
            
        if ([value isKindOfClass:[NSDictionary class]])
        {
            field = [PAMappingEngine generateFieldByDictionary:value withFieldName:fn MappingKey:mappingKey parentMappingKey:parentMappingKey];
        }
        else
        {
            field = [[[PAField alloc] init] autorelease];
            field.parentMappingKey = parentMappingKey;
            field.mappingKey = [NSString stringWithFormat:@"%@/%@", parentMappingKey, fn];
            field.fieldName = fn;
        }
        
        if ([value isKindOfClass:[NSNull class]])
        {
            field.fieldType = PAFIELD_TYPE_NULL;
            field.fieldValue = @"Null";
        }
        else if ([value isKindOfClass:[NSString class]])
        {
            field.fieldType = PAFIELD_TYPE_STRING;
            field.fieldValue = value;
        }
        else if ([value isKindOfClass:[NSNumber class]])
        {
            field.fieldType = PAFIELD_TYPE_NUMBER;
            field.fieldValue = [value stringValue];
        }
        else if ([value isKindOfClass:[NSArray class]])
        {
            field.fieldType = PAFIELD_TYPE_ARRAY;
            NSArray *subfields = [PAMappingEngine generateFieldsByArray:value withFieldName:fn MappingKey:mappingKey parentMappingKey:parentMappingKey];
            for (int i=0;i<subfields.count; i++)
            {
                PAField *f = [subfields objectAtIndex:i];
                f.parentField = field;
            }
            [field.subFields addObjectsFromArray:subfields];
            field.fieldValue = @"";
        }
        
        [ma addObject:field];
    }
    
    return ma;
}




///////////////////////////////////////////

+(NSMutableArray*)propertyFieldsFromJsonFields:(NSArray*)jsonFields inProject:(PAProject*)project inApi:(NSString*)apiName
{
    NSMutableArray *dupFields = [[NSMutableArray alloc] initWithArray:jsonFields copyItems:YES];
    [PAMappingEngine recursiveCreateBeanFields:dupFields inProject:project withMappingKey:[NSString stringWithFormat:@"%@/%@", apiName, PAMAPPING_ROOT_NAME] parentMappingKey:nil];
    return [dupFields autorelease];
}

+(void)recursiveCreateBeanFields:(NSArray*)beanFields inProject:(PAProject*)project withMappingKey:(NSString*)mappingKey parentMappingKey:(NSString*)parentMappingKey
{
    for (int i=0; i<beanFields.count; i++)
    {
        PAField *field = [beanFields objectAtIndex:i];
        
        PABean *b = [project beanForMappingKey:mappingKey];
        if (!b) {
            field.linkStatus = kPAFieldLinkStatusUndefined;
        }
        else
        {
//            field.linkStatus = kPAFieldLinkStatusOK;
            field.beanName = b.beanName;
        }
        
        [PAMappingEngine recursiveCreateBeanField:field inProject:project withMappingKey:field.mappingKey parentMappingKey:field.parentMappingKey];
        for (int i=0;i<field.subFields.count; i++)
        {
            PAField *f = [field.subFields objectAtIndex:i];
            f.parentField = field;
        }
    }
}

+(void)recursiveCreateBeanField:(PAField*)beanField inProject:(PAProject*)project withMappingKey:(NSString*)mappingKey parentMappingKey:(NSString*)parentMappingKey
{
    //recursive till the deepest Object and Array
    for (int i=0; i<beanField.subFields.count; i++)
    {
        PAField *f = [beanField.subFields objectAtIndex:i];
        NSString *mk = [NSString stringWithFormat:@"%@/%@", mappingKey, f.fieldName];
        f.parentField = beanField;
        
        if ([f.fieldType isEqualToString:PAFIELD_TYPE_OBJECT] ||
            [project isBeanType:f])
        {
            [PAMappingEngine recursiveCreateBeanField:f inProject:project withMappingKey:mk parentMappingKey:mappingKey];
        }
        else if ([f.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
        {   
            for (int i=0;i<f.subFields.count; i++)
            {
                PAField *ff = [f.subFields objectAtIndex:i];
                ff.parentField = f;
                if ([ff.fieldType isEqualToString:PAFIELD_TYPE_NUMBER])
                {
                    ff.linkStatus = kPAFieldLinkStatusOK;
                    f.beanName = PAFIELD_TYPE_NUMBER;
                }
                else if ([ff.fieldType isEqualToString:PAFIELD_TYPE_STRING])
                {
                    ff.linkStatus = kPAFieldLinkStatusOK;
                    f.beanName = PAFIELD_TYPE_STRING;
                }
                else
                {
                    [PAMappingEngine recursiveCreateBeanField:ff inProject:project withMappingKey:mk parentMappingKey:mappingKey];
                }
            }
        }
        else
        {
            f.linkStatus = kPAFieldLinkStatusUndefined;
        }
    }
    
    PABean *b = [project beanForMappingKey:mappingKey];
    //the deepest object
    //if mapping exists, copy properties
    if (b)
    {
        NSMutableIndexSet *removeIndexSet = [NSMutableIndexSet indexSet];
        beanField.fieldType = b.beanName;
        beanField.linkStatus = kPAFieldLinkStatusOK;
        for (int i=0; i<beanField.subFields.count; i++)
        {
            PAField *f = [beanField.subFields objectAtIndex:i];
            if ([f.fieldType isEqualToString:PAFIELD_TYPE_ARRAY] ||
                [f.fieldType isEqualToString:PAFIELD_TYPE_OBJECT] ||
                [project isBeanType:f])
            {
                continue ;
            }
            
            [removeIndexSet addIndex:i];
        }
        [beanField.subFields removeObjectsAtIndexes:removeIndexSet];
        
        for (int i=0; i<b.properties.count; i++)
        {
            PAProperty *p = [b.properties objectAtIndex:i];
            
            if ([p.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
            {
                int i=0;
                
                for (; i<beanField.subFields.count; i++)
                {
                    PAField *bsField = [beanField.subFields objectAtIndex:i];
                    
                    if ([bsField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
                    {
                        PABean *b = [project beanForMappingKey:bsField.mappingKey];
                        
                        if ([bsField.fieldName isEqualToString:p.fieldName] &&
                            [p.beanName isEqualToString:b.beanName])
                        {
                            bsField.beanName = p.beanName;
                            bsField.linkStatus = kPAFieldLinkStatusOK;
                            bsField.fromProperty = YES;
                            break;
                        }
                    }
                    else if ([bsField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY] &&
                             ([bsField.beanName isEqualToString:PAFIELD_TYPE_NUMBER] ||
                              [bsField.beanName isEqualToString:PAFIELD_TYPE_STRING]) &&
                             [bsField.beanName isEqualToString:p.beanName] &&
                             [bsField.fieldName isEqualToString:p.fieldName])
                    {
                        bsField.beanName = p.beanName;
                        bsField.linkStatus = kPAFieldLinkStatusOK;
                        bsField.fromProperty = YES;
                        for (int j=0; j<bsField.subFields.count; j++)
                        {
                            PAField *tmp = [bsField.subFields objectAtIndex:j];
                            tmp.fromProperty = YES;
                        }
                        break;
                    }
                    else if ([bsField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY] &&
                             [bsField.fieldName isEqualToString:p.fieldName])
                    {
                        PABean *b = [project beanForMappingKey:bsField.mappingKey];
                        if (b)
                        {
                            bsField.beanName = p.beanName;
                            bsField.linkStatus = kPAFieldLinkStatusOK;
                            bsField.fromProperty = YES;
                            for (int j=0; j<bsField.subFields.count; j++)
                            {
                                PAField *tmp = [bsField.subFields objectAtIndex:j];
                                tmp.fromProperty = YES;
                            }
                            break;
                        }
                    }
                }
                if (i != beanField.subFields.count) {
                    continue ;
                }
            }
            else if ([p.fieldType isEqualToString:PAFIELD_TYPE_OBJECT] ||
                     [project isBeanType:p])
            {
                int i=0;
                
                for (; i<beanField.subFields.count; i++)
                {
                    PAField *bsField = [beanField.subFields objectAtIndex:i];
                    PABean *b = [project beanForMappingKey:bsField.mappingKey];
                    
                    if ([bsField.fieldName isEqualToString:p.fieldName] &&
                        [p.beanName isEqualToString:b.beanName])
                    {
                        bsField.fieldType = p.beanName;
                        bsField.linkStatus = kPAFieldLinkStatusOK;
                        bsField.fromProperty = YES;
                        break;
                    }
                }
                if (i != beanField.subFields.count) {
                    continue ;
                }
            }
            
            NSString *mk = [NSString stringWithFormat:@"%@/%@", mappingKey, p.fieldName];
            
            PAField *f = [[PAField alloc] init];
            f.fieldName = p.fieldName;
            f.fieldType = p.fieldType;
            f.beanName = p.beanName;
            f.fieldValue = @"";
            f.parentMappingKey = mappingKey;
            f.mappingKey = mk;
            f.parentField = beanField;
            f.linkStatus = kPAFieldLinkStatusFail;
            f.fromProperty = YES;
            [beanField.subFields addObject:f];
            [f release];
            
            if ([p.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
            {
                f.fieldType = p.beanName;
            }
        }
    }
    else
    {
        beanField.linkStatus = kPAFieldLinkStatusUndefined;
    }
}

+(void)combineJsonField:(PAField*)jsonField withBeanField:(PAField*)beanField inProject:(PAProject*)project
{
    [jsonField.subFields sortUsingSelector:@selector(caseInsensitiveCompare:)];
    [beanField.subFields sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    
    if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
    {
        for (int i=0; i<jsonField.subFields.count; i++)
        {
            PAField *jsonSubField = [jsonField.subFields objectAtIndex:i];
            PAField *beanSubField = [beanField.subFields objectAtIndex:i];
            
            if ([jsonSubField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT] ||
                     [jsonSubField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
            {
                [PAMappingEngine combineJsonField:jsonSubField withBeanField:beanSubField inProject:project];
            }
        }
    }
    else if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
    {
        //Remove undefine non-Object, non-Array fields
        //        if ([beanField.fieldType isEqualToString:PAFIELD_TYPE_UNDEFINED])
        if (beanField.linkStatus == kPAFieldLinkStatusUndefined)
        {
            NSMutableIndexSet *removeSets = [NSMutableIndexSet indexSet];
            for (int i=0; i<beanField.subFields.count; i++)
            {
                PAField *field = [beanField.subFields objectAtIndex:i];
                if ([field.fieldType isEqualToString:PAFIELD_TYPE_ARRAY] ||
                    [field.fieldType isEqualToString:PAFIELD_TYPE_OBJECT] ||
                    [project isBeanType:field])
                {
                    continue;
                }
                [removeSets addIndex:i];
            }
            [beanField.subFields removeObjectsAtIndexes:removeSets];
        }
        
        
        int i=-1;
        BOOL hasNext = YES;
        
        while (hasNext)
        {
            i++;
            if (i >= jsonField.subFields.count &&
                i >= beanField.subFields.count)
            {
                break;
            }
            
            PAField *jsonSubField = nil;
            PAField *beanSubField = nil;
            
            if (i < jsonField.subFields.count)
            {
                jsonSubField = [jsonField.subFields objectAtIndex:i];
            }
            
            if (i < beanField.subFields.count)
            {
                beanSubField = [beanField.subFields objectAtIndex:i];
            }
            
            // situation 1
            //beanf jsonf
            // a    a
            // _    b
            // or
            // a    a
            // b    _
            if (!jsonSubField) {
                PAField *ef = [PAField emptyField];
                ef.parentField = jsonField;
                beanSubField.linkStatus = kPAFieldLinkStatusFail;
                [jsonField.subFields addObject:ef];
                continue ;
            }
            
            if (!beanSubField) {
                PAField *ef = [PAField emptyField];
                ef.parentField = beanField;
                [beanField.subFields addObject:ef];
                continue ;
            }
            
            // bean < json
            // bean     _
            
            // bean > json
            //  _     json
            
            // bean == json (Object with non-Object)
            // bean     _
            //  _      json
            
            
            if ([jsonSubField.mappingKey isEqualToString:beanSubField.mappingKey])
            {
                if ([jsonSubField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT] &&
                    ([beanSubField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT] ||
                     [project isBeanType:beanSubField])
                    )
                {
                    //                    beanSubField.linkStatus = kPAFieldLinkStatusOK;
                    [PAMappingEngine combineJsonField:jsonSubField withBeanField:beanSubField inProject:project];
                }
                else if([jsonSubField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY] &&
                        [beanSubField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
                {
                    if ([jsonSubField.fieldName isEqualToString:beanSubField.fieldName])
                    {
                        //                        beanSubField.linkStatus = kPAFieldLinkStatusOK;
                    }
                    else
                    {
                        beanSubField.linkStatus = kPAFieldLinkStatusFail;
                    }
                    
                    [PAMappingEngine combineJsonField:jsonSubField withBeanField:beanSubField inProject:project];
                }
                else
                {
                    //bean < json
                    if ([beanSubField caseInsensitiveCompare:jsonSubField] == NSOrderedAscending)
                    {
                        PAField *ef = [PAField emptyField];
                        ef.parentField = jsonField;
                        beanSubField.linkStatus = kPAFieldLinkStatusFail;
                        [jsonField.subFields insertObject:ef atIndex:i];
                    }
                    //bean > json
                    else if ([beanSubField caseInsensitiveCompare:jsonSubField] == NSOrderedDescending)
                    {
                        PAField *ef = [PAField emptyField];
                        ef.parentField = beanField;
                        [beanField.subFields insertObject:ef atIndex:i];
                    }
                    else
                    {
                        if (![beanSubField.fieldType isEqualToString:jsonSubField.fieldType])
                        {
                            beanSubField.linkStatus = kPAFieldLinkStatusFail;
//                            PAField *efj = [PAField emptyField];
//                            efj.parentField = jsonField;
//                            PAField *efb = [PAField emptyField];
//                            efb.parentField = beanField;
//                            
//                            beanSubField.linkStatus = kPAFieldLinkStatusFail;
//                            
//                            [jsonField.subFields insertObject:efj atIndex:i];
//                            [beanField.subFields insertObject:efb atIndex:i+1];
//                            i++;
                        }
                        else
                        {
                            beanSubField.linkStatus = kPAFieldLinkStatusOK;
                        }
                    }
                }
            }
            else
            {
                //bean < json
                if ([beanSubField caseInsensitiveCompare:jsonSubField] == NSOrderedAscending)
                {
                    PAField *ef = [PAField emptyField];
                    ef.parentField = jsonField;
                    beanSubField.linkStatus = kPAFieldLinkStatusFail;
                    [jsonField.subFields insertObject:ef atIndex:i];
                }
                //bean > json
                else if ([beanSubField caseInsensitiveCompare:jsonSubField] == NSOrderedDescending)
                {
                    PAField *ef = [PAField emptyField];
                    ef.parentField = beanField;
                    [beanField.subFields insertObject:ef atIndex:i];
                }
                else
                {
                    PAField *efj = [PAField emptyField];
                    efj.parentField = jsonField;
                    PAField *efb = [PAField emptyField];
                    efb.parentField = beanField;
                    
                    beanSubField.linkStatus = kPAFieldLinkStatusFail;
                    
                    [jsonField.subFields insertObject:efj atIndex:i];
                    [beanField.subFields insertObject:efb atIndex:i+1];
                    i++;
                }
            }
        }
    }
}

+(BOOL)canCreateFromJsonField:(PAField*)jsonField toBeanField:(PAField*)beanField inProject:(PAProject*)project
{
    if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
    {
        return YES;
    }
    
    return NO;
}

+(BOOL)canMapFromJsonField:(PAField*)jsonField toBeanField:(PAField*)beanField inProject:(PAProject*)project
{
    if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_EMPTY] ||
        [jsonField.fieldType isEqualToString:PAFIELD_TYPE_NULL])
    {
        return NO;
    }
    
    //single property assignment
    if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_STRING] ||
        [jsonField.fieldType isEqualToString:PAFIELD_TYPE_NUMBER] ||
        [jsonField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT] ||
        [jsonField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
    {
        if (beanField.fromProperty && beanField.linkStatus == kPAFieldLinkStatusOK) {
            return NO;
        }
        
        PAField *parent = beanField.parentField;
        if (![project isBeanType:parent])
        {
            return NO;
        }
        
        //parent has same name property
        PABean *bean = [project beanFormName:parent.beanName];
        if (bean) {
            for (int i=0; i<bean.properties.count; i++)
            {
                PAProperty *p = [bean.properties objectAtIndex:i];
                if ([p.fieldName isEqualToString:beanField.fieldName]) {
                    return NO;
                }
            }
        }
        
        return YES;
    }
    
    //Array assignment, basically the same as Object assignment
//    if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
//    {
//        if ([beanField.beanName isEqualToString:PAFIELD_TYPE_STRING] ||
//            [beanField.beanName isEqualToString:PAFIELD_TYPE_NUMBER])
//        {
//            return NO;
//        }
//        
//        return YES;
//    }
    
    return NO;
}

+(BOOL)canSmartMapFromJsonField:(PAField*)jsonField toBeanField:(PAField*)beanField inProject:(PAProject*)project
{
    if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_EMPTY] ||
        [jsonField.fieldType isEqualToString:PAFIELD_TYPE_NULL])
    {
        return NO;
    }
    
    if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_STRING] ||
        [jsonField.fieldType isEqualToString:PAFIELD_TYPE_NUMBER] ||
        [jsonField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
    {
        if (beanField.linkStatus == kPAFieldLinkStatusOK) {
            return NO;
        }
        
        PAField *parent = beanField.parentField;
        if (![project isBeanType:parent])
        {
            return NO;
        }
        
        return YES;
    }
    
    if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
    {
        return YES;
    }
    
    return NO;
}

+(BOOL)canDeleteMapFromBeanField:(PAField*)beanField inProject:(PAProject*)project
{
    if ([beanField.fieldType isEqualToString:PAFIELD_TYPE_EMPTY] ||
        [beanField.fieldType isEqualToString:PAFIELD_TYPE_NULL])
    {
        return NO;
    }
    
    PAField *parent = beanField.parentField;
    if (![project isBeanType:parent] || !beanField.fromProperty)
    {
        return NO;
    }
    
    return YES;
}

#pragma mark -
#pragma mark *****  *****
+(BOOL)mapJsonField:(PAField*)jsonField toBeanField:(PAField*)beanField inProject:(PAProject*)project forceCreate:(BOOL)forceCreate
{
    if (![PAMappingEngine canMapFromJsonField:jsonField toBeanField:beanField inProject:project])
    {
        return NO;
    }
    
    PABean *bean = [project beanForMappingKey:jsonField.parentMappingKey];
    
    if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_STRING] ||
        [jsonField.fieldType isEqualToString:PAFIELD_TYPE_NUMBER])
    {
        PAProperty *p = [bean addPropertyByField:jsonField];
        p.parentBean = bean;
    }
    else if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
    {
        PABean *bestBean = [PAMappingEngine bestBeanForField:jsonField inProject:project];
        if (forceCreate)
        {
            ;
        }
        else if (bestBean)
        {
            jsonField.beanName = bestBean.beanName;
            PAProperty *p = [bean addPropertyByField:jsonField];
            [project addMapping:jsonField.mappingKey forBeanName:bestBean.beanName];
            p.parentBean = bean;
        }
        else
        {
            PABean *newBean = [PAMappingEngine createBeanForJsonField:jsonField inProject:project toTmpArray:[NSMutableArray array]];
            [project insertBeans:[NSArray arrayWithObject:newBean]];
            jsonField.beanName = newBean.beanName;
            PAProperty *p = [bean addPropertyByField:jsonField];
            [project addMapping:jsonField.mappingKey forBeanName:newBean.beanName];
            p.parentBean = bean;
        }
    }
    else if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
    {
        if (jsonField.subFields.count == 0) {
//            jsonField.beanName = PAFIELD_TYPE_STRING;
            PAProperty *newArrayProperty = [bean addPropertyByField:jsonField];
            newArrayProperty.parentBean = bean;
        }
        else
        {
            PAField *subField = [jsonField.subFields objectAtIndex:0];
            jsonField.beanName = subField.fieldType;
            PAProperty *newArrayProperty = [bean addPropertyByField:jsonField];
            newArrayProperty.parentBean = bean;
            if ([subField.fieldType isEqualToString:PAFIELD_TYPE_STRING] ||
                [subField.fieldType isEqualToString:PAFIELD_TYPE_NUMBER])
            {
                newArrayProperty.beanName = subField.fieldType;
            }
            else if ([subField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
            {
                PABean *tmpBean = [project beanForMappingKey:subField.mappingKey];
                if (tmpBean) {
                    newArrayProperty.beanName = tmpBean.beanName;
                }
                else
                {
                    PABean *bestBean = [PAMappingEngine bestBeanForField:subField inProject:project];
                    if (forceCreate)
                    {
                        ;
                    }
                    else if (bestBean)
                    {
                        newArrayProperty.beanName = bestBean.beanName;
                        [project addMapping:subField.mappingKey forBeanName:bestBean.beanName];
                        //                        subField.beanName = bestBean.beanName;
                        //                        PAProperty *p = [bean addPropertyByField:subField];
                        //                        [project addMapping:subField.mappingKey forBeanName:bestBean.beanName];
                        //                        p.parentBean = bean;
                    }
                    else
                    {
                        PABean *newBean = [PAMappingEngine createBeanForJsonField:subField inProject:project toTmpArray:[NSMutableArray array]];
                        newArrayProperty.beanName = newBean.beanName;
                        [project insertBeans:[NSArray arrayWithObject:newBean]];
                        [project addMapping:subField.mappingKey forBeanName:newBean.beanName];
                        
                        //                        PABean *newBean = [PAMappingEngine createBeanForJsonField:subField inProject:project toTmpArray:[NSMutableArray array]];
                        //                        [project insertBeans:[NSArray arrayWithObject:newBean]];
                        //                        subField.beanName = newBean.beanName;
                        //                        PAProperty *p = [bean addPropertyByField:subField];
                        //                        [project addMapping:subField.mappingKey forBeanName:newBean.beanName];
                        //                        p.parentBean = bean;
                    }
                }
            }
        }
    }
    return YES;
}

+(PABean*)bestBeanForField:(PAField*)field inProject:(PAProject*)project
{
    CGFloat maxRate = 0.5;
    PABean *bestBean = nil;
    
    for (int i=0; i<project.beans.allChildren.count; i++)
    {
        PABean *b = [project.beans.allChildren objectAtIndex:i];
        CGFloat rate = [PAMappingEngine countMatchingRateForField:field withBean:b];
        if (rate > maxRate)
        {
            maxRate = rate;
            bestBean = b;
        }
    }
    
    NSLog(@"maxRate:%f BestBean:%@", maxRate, bestBean.beanName);
    return bestBean;
}

+(CGFloat)countMatchingRateForField:(PAField*)field withBean:(PABean*)bean
{
    CGFloat rate = 0.0;
    for (int i=0; i<field.subFields.count; i++)
    {
        PAField *subField = [field.subFields objectAtIndex:i];
        if ([bean hasPropertyField:subField])
        {
            rate += 1;
        }
    }
    
    rate /= field.subFields.count;
    return rate;
}

+(PABean*)createBeanForJsonField:(PAField*)jsonField inProject:(PAProject*)project toTmpArray:(NSMutableArray*)tmpArray
{
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:10];
    [tmp setArray:project.beans.allChildren];
    if (tmpArray.count > 0) {
        [tmp addObjectsFromArray:tmpArray];
    }
    
    PABean *existBean = [project beanForMappingKey:jsonField.mappingKey];
    if (existBean) {
        [project removeMapping:jsonField.mappingKey forBeanName:existBean.beanName];
    }
    
    PABean *bean = [[PABean alloc] init];
    bean.name = [PAObject object:bean valueByValue:jsonField.fieldName forKey:@"name" existsObjects:tmp];
    bean.beanName = [PAObject object:bean valueByValue:jsonField.fieldName forKey:@"beanName" existsObjects:tmp];;
    bean.beanType = jsonField.fieldType;
    bean.project = project;
    
    for (int i=0; i<jsonField.subFields.count; i++)
    {
        PAField *subField = [jsonField.subFields objectAtIndex:i];
        if ([subField.fieldType isEqualToString:PAFIELD_TYPE_EMPTY] )
        {
            continue ;
        }
        
        PAProperty *property = [[PAProperty alloc] init];
        property.name = subField.fieldName;
        property.fieldName = subField.fieldName;
        property.fieldType = subField.fieldType;
        property.parentBean = bean;
        property.fromProperty = YES;
        property.defaultValue = @"";
        property.mappingKey = subField.mappingKey;
        property.parentMappingKey = subField.parentMappingKey;
        
        //Default Null to String
        if ([subField.fieldType isEqualToString:PAFIELD_TYPE_NULL]) {
            property.fieldType = PAFIELD_TYPE_STRING;
        }
        else if ([subField.fieldType isEqualToString:PAFIELD_TYPE_STRING] ||
                 [subField.fieldType isEqualToString:PAFIELD_TYPE_NUMBER])
        {
            ;
        }
        else if ([subField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
        {
            PABean *b = [project beanForMappingKey:subField.mappingKey];
            if (b)
            {
                property.beanName = b.beanName;
            }
            else
            {
                b = [PAMappingEngine createBeanForJsonField:subField inProject:project toTmpArray:tmpArray];
                b.rowIndex = project.beans.allChildren.count;
                [project insertBeans:[NSArray arrayWithObject:b]];
                [project addMapping:subField.mappingKey forBeanName:b.beanName];
                property.beanName = b.beanName;
            }
            
        }
        else if ([subField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
        {
            PABean *b = [project beanForMappingKey:subField.mappingKey];
            if (b)
            {
                property.beanName = b.beanName;
            }
            else if (subField.subFields.count > 0)
            {
                PAField *sf = [subField.subFields objectAtIndex:0];
                if ([sf.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
                {
                    sf.fieldName = subField.fieldName;
                    PABean *tmp = [project beanForMappingKey:sf.mappingKey];
                    if (tmp) {
                        property.beanName = tmp.beanName;
                    }
                    else
                    {
                        tmp = [PAMappingEngine createBeanForJsonField:sf inProject:project toTmpArray:tmpArray];
                        tmp.rowIndex = project.beans.allChildren.count;
                        [project insertBeans:[NSArray arrayWithObject:tmp]];
                        [project addMapping:sf.mappingKey forBeanName:tmp.beanName];
                        property.beanName = tmp.beanName;
                    }
                }
                else if ([sf.fieldType isEqualToString:PAFIELD_TYPE_STRING] ||
                         [sf.fieldType isEqualToString:PAFIELD_TYPE_NUMBER])
                {
                    property.beanName = sf.fieldType;
                }
            }
        }
        
        [bean.properties addObject:property];
        [property release];
    }
    
    [tmpArray addObject:bean];
//    [project.beans.allChildren addObject:bean];
//    [project.beans.children addObject:bean];
    return [bean autorelease];
}

+(PABean*)createBeanForDictionary:(NSDictionary*)dict withKey:(NSString*)key inProject:(PAProject*)project toTmpArray:(NSMutableArray*)tmpArray
{
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:10];
    [tmp setArray:project.beans.allChildren];
    [tmp addObjectsFromArray:tmpArray];
    
    if (!key) {
        key = @"NewBean";
    }
    
    PABean *bean = [[PABean alloc] init];
    bean.name = [PAObject object:bean valueByValue:key forKey:@"name" existsObjects:tmp];
    bean.beanName = [PAObject object:bean valueByValue:key forKey:@"beanName" existsObjects:tmp];;
    bean.beanType = @"Object";
    bean.project = project;
    
    [tmpArray addObject:bean];
    
    NSArray *keys = [dict allKeys];
    for (int i=0; i<keys.count; i++)
    {
        NSString *k = [keys objectAtIndex:i];
        id value = [dict objectForKey:k];
        NSString *ptype = nil;
        
        PAProperty *property = [[PAProperty alloc] init];
        property.name = [PAObject object:property valueByValue:k forKey:@"name" existsObjects:bean.properties];
        property.fieldName = [PAObject object:property valueByValue:k forKey:@"name" existsObjects:bean.properties];
        property.parentBean = bean;
        if (value == [NSNull null]||
            [value isKindOfClass:[NSString class]])
        {
            ptype = PAFIELD_TYPE_STRING;
        }
        else if ([value isKindOfClass:[NSNumber class]])
        {
            ptype = PAFIELD_TYPE_NUMBER;
        }
        else if ([value isKindOfClass:[NSDictionary class]])
        {
            ptype = PAFIELD_TYPE_OBJECT;
            PABean *b = [PAMappingEngine createBeanForDictionary:value withKey:k inProject:project toTmpArray:tmpArray];
            property.beanName = b.beanName;
        }
        else if ([value isKindOfClass:[NSArray class]])
        {
            ptype = PAFIELD_TYPE_ARRAY;
            NSString *subptype = nil;
            
            NSArray *arr = value;
            if (arr.count > 0) {
                id subvalue = [arr objectAtIndex:0];
                if (subvalue == [NSNull null]||
                    [subvalue isKindOfClass:[NSString class]])
                {
                    subptype = PAFIELD_TYPE_STRING;
                    property.beanName = PAFIELD_TYPE_STRING;
                }
                else if ([subvalue isKindOfClass:[NSNumber class]])
                {
                    subptype = PAFIELD_TYPE_NUMBER;
                    property.beanName = PAFIELD_TYPE_NUMBER;
                }
                else if ([subvalue isKindOfClass:[NSDictionary class]])
                {
                    subptype = PAFIELD_TYPE_OBJECT;
                    PABean *b = [PAMappingEngine createBeanForDictionary:subvalue withKey:k inProject:project toTmpArray:tmpArray];
                    property.beanName = b.beanName;
                }
            }
        }
        
        property.fieldType = ptype;
        
        [bean.properties addObject:property];
        
        [property release];
    }
    
    return [bean autorelease];
}

+(BOOL)smartMapJsonField:(PAField*)jsonField toBeanField:(PAField*)beanField inProject:(PAProject*)project
{
    if (![PAMappingEngine canSmartMapFromJsonField:jsonField toBeanField:beanField inProject:project])
    {
        return NO;
    }
    
    if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_STRING] ||
        [jsonField.fieldType isEqualToString:PAFIELD_TYPE_NUMBER] ||
        [jsonField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
    {
        if (beanField.linkStatus == kPAFieldLinkStatusOK) {
            return NO;
        }
        
        PAField *parent = beanField.parentField;
        if (![project isBeanType:parent])
        {
            return NO;
        }
        
        if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_STRING] ||
            [jsonField.fieldType isEqualToString:PAFIELD_TYPE_NUMBER])
        {
            return [PAMappingEngine mapJsonField:jsonField toBeanField:beanField inProject:project forceCreate:NO];
        }
        else if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
        {
            return [PAMappingEngine mapJsonField:jsonField toBeanField:beanField inProject:project forceCreate:NO];
        }
    }
    
    if ([jsonField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
    {
        PABean *b = [project beanForMappingKey:jsonField.mappingKey];
        if (!b) {
            b = [PAMappingEngine bestBeanForField:jsonField inProject:project];
            if (b) {
                [project addMapping:jsonField.mappingKey forBeanName:b.beanName];
            }
        }
        
        if (b)
        {
            PAField *parentField = jsonField.parentField;
            PABean *parentBean = [project beanForMappingKey:parentField.mappingKey];
            if (parentBean && !beanField.fromProperty)
            {
                jsonField.beanName = b.beanName;
                PAProperty *p = [parentBean addPropertyByField:jsonField];
                p.parentBean = parentBean;
            }
            else
            {
                //already mapped, fill all properties
                for (int i=0; i<jsonField.subFields.count; i++)
                {
                    PAField *subField = [jsonField.subFields objectAtIndex:i];
                    PAField *beanSub = [beanField.subFields objectAtIndex:i];
                    [PAMappingEngine smartMapJsonField:subField toBeanField:beanSub inProject:project];
                    
                }
            }

        }
        else
        {
            //not mapped, create
            PABean *b = [PAMappingEngine createBeanForJsonField:jsonField inProject:project toTmpArray:nil];
            b.rowIndex = project.beans.allChildren.count;
            [project insertBeans:[NSArray arrayWithObject:b]];
            [project addMapping:jsonField.mappingKey forBeanName:b.beanName];
            
            PAField *parentField = jsonField.parentField;
            PABean *parentBean = [project beanForMappingKey:parentField.mappingKey];
            if (parentBean && !beanField.fromProperty)
            {
                jsonField.beanName = b.beanName;
                PAProperty *p = [parentBean addPropertyByField:jsonField];
                p.parentBean = parentBean;
            }
            
        }
        
        
        return YES;
    }
    
    return NO;
}

+(BOOL)addPropertiesToBean:(PABean*)bean fromJsonField:(PAField*)jsonField
{
    
}
@end