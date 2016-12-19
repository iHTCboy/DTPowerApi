//
//  PAProject.m
//  PowerApi
//
//  Created by leks on 12-7-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PAProject.h"
#import "PAApi.h"
#import "PABean.h"
#import "PAApiFolder.h"
#import "PABeanFolder.h"
#import "DTUtil.h"
#import "PAField.h"
#import "Global.h"
#import "GTMBase64.h"
#import "PAParam.h"

@implementation PAProject
@synthesize baseUrl;
@synthesize websiteUrl;
@synthesize apis;
@synthesize beans;
@synthesize encoding;
@synthesize mapping;
@synthesize allProjectsRefs;
@synthesize commonGetParams;
@synthesize commonPostDatas;

-(void)dealloc
{
    [baseUrl release];
    [websiteUrl release];
    [apis release];
    [beans release];
    [mapping release];
    [commonGetParams release];
    [commonPostDatas release];
    [super dealloc];
}

-(id)init
{
    if (self = [super init]) {
        self.apis = [[[PAApiFolder alloc] init] autorelease];
        self.apis.project = self;
        self.beans = [[[PABeanFolder alloc] init] autorelease];
        self.beans.project = self;
        self.mapping = [[[PAMapping alloc] init] autorelease];
        self.commonGetParams = [NSMutableArray arrayWithCapacity:10];
        self.commonPostDatas = [NSMutableArray arrayWithCapacity:10];
        self.type = PAOBJECT_NAME_PROJECT;
        self.typeName = PAOBJECT_NAME_PROJECT;
        self.desc = PAOBJECT_DESC_PROJECT;
        self.baseUrl = @"";
        self.websiteUrl = @"";
    }
    
    return self;
}

-(NSDictionary*)toDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    [md setDictionary:[super toDict]];
    
    DICT_EXPORT1(baseUrl);
    DICT_EXPORT1(websiteUrl);
    [md setObject:[apis toDict] forKey:@"apis"];
    [md setObject:[beans toDict] forKey:@"beans"];
    [md setObject:[mapping toDict] forKey:@"mapping"];
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
    for (int i=0; i<self.commonGetParams.count; i++)
    {
        PAParam *p = [self.commonGetParams objectAtIndex:i];
        [ma addObject:[p toDict]];
    }
    [md setObject:ma forKey:@"commonGetParams"];
    
    ma = [NSMutableArray arrayWithCapacity:10];
    for (int i=0; i<self.commonPostDatas.count; i++)
    {
        PAParam *p = [self.commonPostDatas objectAtIndex:i];
        [ma addObject:[p toDict]];
    }
    [md setObject:ma forKey:@"commonPostDatas"];
    
    return md;
}

-(id)initWithDict:(NSDictionary*)dict
{
    if (self = [super initWithDict:dict])
    {
        self.type = PAOBJECT_NAME_PROJECT;
        self.typeName = PAOBJECT_NAME_PROJECT;
        self.desc = PAOBJECT_DESC_PROJECT;
        
        DICT_ASSIGN1(baseUrl);
        DICT_ASSIGN1(websiteUrl);
        NSDictionary *apiDict = [dict objectForKey:@"apis"];
        NSDictionary *beanDict = [dict objectForKey:@"beans"];
        NSDictionary *mappingDict = [dict objectForKey:@"mapping"];
        
        self.apis = [[[PAApiFolder alloc] initWithDict:apiDict] autorelease];
        self.apis.project = self;
        self.beans = [[[PABeanFolder alloc] initWithDict:beanDict] autorelease];
        self.beans.project = self;
        self.mapping = [[[PAMapping alloc] initWithDict:mappingDict] autorelease];
        
        for (int i=0; i<self.apis.allChildren.count; i++)
        {
            PAApi *api = [self.apis.allChildren objectAtIndex:i];
            api.project = self;
        }
        
        for (int i=0; i<self.beans.allChildren.count; i++)
        {
            PABean *bean = [self.beans.allChildren objectAtIndex:i];
            bean.project = self;
        }
        
        NSArray *tmp = [dict objectForKey:@"commonGetParams"];
        self.commonGetParams = [NSMutableArray arrayWithCapacity:10];
        for (int i=0; i<tmp.count; i++)
        {
            NSDictionary *d = [tmp objectAtIndex:i];
            PAParam *p = [[PAParam alloc] initWithDict:d];
            [self.commonGetParams addObject:p];
            [p release];
        }
        
        tmp = [dict objectForKey:@"commonPostDatas"];
        self.commonPostDatas = [NSMutableArray arrayWithCapacity:10];
        for (int i=0; i<tmp.count; i++)
        {
            NSDictionary *d = [tmp objectAtIndex:i];
            PAParam *p = [[PAParam alloc] initWithDict:d];
            [self.commonPostDatas addObject:p];
            
        }
    }
    return self;
}

-(PABean*)beanForMappingKey:(NSString*)mappingKey
{
    NSString *beanName = [self.mapping.beanMapping objectForKey:mappingKey];
    return [self beanFormName:beanName];
}

-(PABean*)beanFormName:(NSString*)beanName
{
    for (int i=0; i<self.beans.allChildren.count; i++)
    {
        PABean *b = [self.beans.allChildren objectAtIndex:i];
        if ([b.beanName isEqualToString:beanName])
        {
            return b;
        }
    }
    return nil;
}

-(void)addMapping:(NSString*)mappingKey forBeanName:(NSString*)beanName
{
    NSUndoManager *undo = [GlobalSetting undoManager];
    [undo beginUndoGrouping];
    [[undo prepareWithInvocationTarget:self] removeMapping:mappingKey forBeanName:beanName];
    [self.mapping.beanMapping setObject:beanName forKey:mappingKey];
    PABean *b = [self beanForMappingKey:mappingKey];
    [b addMappingKey:mappingKey];
    
    [undo endUndoGrouping];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_BEANS_CHANGED object:nil];
}

-(void)removeMapping:(NSString*)mappingKey forBeanName:(NSString*)beanName
{
    NSUndoManager *undo = [GlobalSetting undoManager];
    [undo beginUndoGrouping];
    
    [[undo prepareWithInvocationTarget:self] addMapping:mappingKey forBeanName:beanName];
    PABean *b = [self beanForMappingKey:mappingKey];
    [b removeMappingKey:mappingKey];
    NSString *bname = [self.mapping.beanMapping objectForKey:mappingKey];
    if ([bname isEqualToString:beanName]) {
        [self.mapping.beanMapping removeObjectForKey:mappingKey];
    }
    
    [undo endUndoGrouping];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_BEANS_CHANGED object:nil];
}

-(NSArray*)beanNames
{
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
    for (int i=0; i<self.beans.allChildren.count; i++)
    {
        PABean *b = [self.beans.allChildren objectAtIndex:i];
        [ma addObject:b.beanName];
    }
    
    return ma;
}

-(BOOL)isBeanType:(PAField*)field
{
    for (int i=0; i<self.beans.allChildren.count; i++)
    {
        PABean *b = [self.beans.allChildren objectAtIndex:i];
        if ([field.fieldType isEqualToString:b.beanName])
        {
            return YES;
        }
    }
    
    return NO;
}

+(NSMutableArray*)projectsForDictionary:(NSDictionary*)dict
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:10];
    
    if (!dict) {
        return nil;
    }
    
    NSDictionary *tmp = dict;//[[[NSDictionary alloc] initWithContentsOfFile:url.path] autorelease];
    if (tmp) {
        NSArray *projectsArray = [tmp objectForKey:PAFILE_PROJECT_DATAS_KEY];
        NSString *sourceType = [tmp objectForKey:PAOBJECT_SOURCE_TYPE];
        
        if ([sourceType isEqualToString:PAOBJECT_NAME_FILE] && projectsArray.count > 0)
        {
            for (int i=0; i<projectsArray.count; i++)
            {
                NSDictionary *dict = [projectsArray objectAtIndex:i];
                sourceType = [dict objectForKey:@"type"];
                if ([sourceType isEqualToString:PAOBJECT_NAME_PROJECT])
                {
                    PAProject *project = [[PAProject alloc] initWithDict:dict];
                    [result addObject:project];
                    [project release];
                }
            }
        }
    }

    return result;
}

-(id)copyWithZone:(NSZone *)zone
{
    PAProject *project = [super copyWithZone:zone];
    if (project) {
        project.baseUrl = [self.baseUrl copyWithZone:zone];
        project.websiteUrl = [self.websiteUrl copyWithZone:zone];
        project.encoding = self.encoding;
        project.apis = [self.apis copyWithZone:zone];
        project.beans = [self.beans copyWithZone:zone];
    }
    
    return project;
}

-(NSString*)bean:(PABean*)bean valueByValue:(NSString*)value forKey:(NSString*)key
{
    NSMutableString *ms = [NSMutableString stringWithString:value];
    int i=1;
    while ([PAObject object:bean ValueExists:ms forKey:key existsObjects:self.beans.allChildren])
    {
        [ms setString:[NSString stringWithFormat:@"%@_%d", value, i]];
        i++;
    }
    return ms;
}

-(NSString*)api:(PAApi*)api valueByValue:(NSString*)value forKey:(NSString*)key
{
    NSMutableString *ms = [NSMutableString stringWithString:value];
    int i=1;
    while ([PAObject object:api ValueExists:ms forKey:key existsObjects:self.apis.allChildren])
    {
        [ms setString:[NSString stringWithFormat:@"%@_%d", value, i]];
        i++;
    }
    return ms;
}

-(void)setValue:(id)value forKey:(NSString *)key
{
    if ([key isEqualToString:@"name"])
    {
        BOOL exists = [self projectNameExists:value];
        if (!exists && value && [value length]>0) {
            [super setValue:value forKey:key];
        }
        else
        {
            NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
            [md setObject:[self className] forKey:@"object_type"];
            [md setObject:key forKey:@"key"];
            [md setObject:[self valueForKey:key] forKey:@"value"];
            [md setObject:self forKey:@"object"];
            
            if (!value || [value length] == 0) {
                [md setObject:@"Project name can not be empty!" forKey:@"msg"];;
            }
            else
            {
                [md setObject:@"Project name already exists!" forKey:@"msg"];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_OBJECT_VALUE_EXISTS object:md];
        }
    }
    else
    {
        [super setValue:value forKey:key];
    }
}

-(BOOL)projectNameExists:(NSString*)pname
{
    for (int i=1; i<self.allProjectsRefs.count; i++)
    {
        PAProject *project = [self.allProjectsRefs objectAtIndex:i];
        if (project == self) {
            continue;
        }
        NSString *pvalue = [project valueForKey:@"name"];
        
        if ([pname isEqualToString:pvalue])
        {
            return YES;
        }
    }
    return NO;
}

-(void)insertBeans:(NSArray *)array
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:10];
    [tmp setArray:self.beans.allChildren];
    
    for (int i=0; i<array.count; i++)
    {
        PABean *b = [array objectAtIndex:i];
        if (b.rowIndex > tmp.count) {
            [indexSet addIndex:tmp.count];
        }
        else
        {
            [indexSet addIndex:b.rowIndex];
        }
        b.beanName = [PAObject object:b valueByValue:b.beanName forKey:@"beanName" existsObjects:tmp];
        b.name = [PAObject object:b valueByValue:b.name forKey:@"name" existsObjects:tmp];
        b.project = self;
        [tmp addObject:b];
    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeBeans:array];
    
    [self recoverBeanMappings:array];
    [self.beans.allChildren insertObjects:array atIndexes:indexSet];
    [self.beans refilterChildren];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          array, @"beans", 
                          @"insert", @"operation",
                          indexSet, @"indexSet", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_BEANS_CHANGED object:dict];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_CHILDREN_NUMBER_CHANGED object:self.beans];
    
}

-(void)removeBeans:(NSArray *)array
{
    NSIndexSet *indexSet = [PAObject indexesForObjects:array inArray:self.beans.allChildren];
//    for (int i=0; i<array.count; i++)
//    {
//        PABean *b = [array objectAtIndex:i];
//        [indexSet addIndex:b.rowIndex];
//    }
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [undoManager beginUndoGrouping];
    //remove bean types
    for (int i=0; i<array.count; i++)
    {
        PABean *removeBean = [array objectAtIndex:i];
        for (int j=0; j<self.beans.allChildren.count; j++)
        {
            PABean *existBean = [self.beans.allChildren objectAtIndex:j];
            NSMutableArray *ma = [NSMutableArray array];
            for (int k=0; k<existBean.properties.count; k++)
            {
                PAProperty *property = [existBean.properties objectAtIndex:k];
                
                if ([property.fieldType isEqualToString:PAFIELD_TYPE_OBJECT] ||
                    [property.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
                {
                    if ([property.beanName isEqualToString:removeBean.beanName])
                    {
                        [ma addObject:property];
                    }
                }
            }
            if (ma.count > 0)
            {
                [existBean removeProperties:ma];
            }
        }
    }
    
    [[undoManager prepareWithInvocationTarget:self] insertBeans:array];
    
    [self removeBeanMappings:array];
    [self.beans.allChildren removeObjectsAtIndexes:indexSet];
    [self.beans refilterChildren];
    
    [undoManager endUndoGrouping];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          array, @"beans", 
                          @"remove", @"operation",
                          indexSet, @"indexSet", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_BEANS_CHANGED object:dict];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_CHILDREN_NUMBER_CHANGED object:self.beans];
}

-(void)removeBeanMappings:(NSArray *)array
{
    NSArray *subSets = array;
    for (int i=0; i<subSets.count; i++)
    {
        PABean *b = [subSets objectAtIndex:i];
        for (int j=0; j<b.mappings.count; j++)
        {
            NSString *bmappingKey = [b.mappings objectAtIndex:j];
            [self.mapping.beanMapping removeObjectForKey:bmappingKey];
        }
    }
}

-(void)recoverBeanMappings:(NSArray *)array
{
    NSArray *subSets = array;
    for (int i=0; i<subSets.count; i++)
    {
        PABean *b = [subSets objectAtIndex:i];
        for (int j=0; j<b.mappings.count; j++)
        {
            NSString *bmappingKey = [b.mappings objectAtIndex:j];
            [self.mapping.beanMapping setObject:b.beanName forKey:bmappingKey];
        }
    }
}

-(void)insertApis:(NSArray *)array
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:10];
    [tmp setArray:self.apis.allChildren];
    
    for (int i=0; i<array.count; i++)
    {
        PAApi *a = [array objectAtIndex:i];
        if (a.rowIndex > tmp.count) {
            [indexSet addIndex:tmp.count];
        }
        else
        {
            [indexSet addIndex:a.rowIndex];
        }
        a.name = [PAObject object:a valueByValue:a.name forKey:@"name" existsObjects:tmp];
        a.project = self;
        [tmp addObject:a];
    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeApis:array];
    [self.apis.allChildren insertObjects:array atIndexes:indexSet];
    [self.apis refilterChildren];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          array, @"apis",
                          @"insert", @"operation",
                          indexSet, @"indexSet", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_APIS_CHANGED object:dict];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_CHILDREN_NUMBER_CHANGED object:self.apis];
}

-(void)removeApis:(NSArray *)array
{
    NSIndexSet *indexSet = [PAObject indexesForObjects:array inArray:self.apis.allChildren];
//    for (int i=0; i<array.count; i++)
//    {
//        PAApi *a = [array objectAtIndex:i];
//        [indexSet addIndex:a.rowIndex];
//    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] insertApis:array];
    [self.apis.allChildren removeObjectsAtIndexes:indexSet];
    [self.apis refilterChildren];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          array, @"apis",
                          @"remove", @"operation",
                          indexSet, @"indexSet", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_APIS_CHANGED object:dict];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_CHILDREN_NUMBER_CHANGED object:self.apis];
}

-(void)bean:(PABean*)bean name:(NSString*)beanName changeTo:(NSString*)newBeanName
{
    NSArray *keys = [self.mapping.beanMapping allKeys];
    for (NSString *k in keys)
    {
        NSString *v = [self.mapping.beanMapping objectForKey:k];
        if ([v isEqualToString:beanName])
        {
            [self.mapping.beanMapping setValue:newBeanName forKey:k];
        }
    }
    
    for (int i=0; i<self.beans.allChildren.count; i++)
    {
        PABean *b = [self.beans.allChildren objectAtIndex:i];
        for (int j=0; j<b.properties.count; j++)
        {
            PAProperty *p = [b.properties objectAtIndex:j];
            if ([p.beanName isEqualToString:beanName])
            {
                p.beanName = newBeanName;
            }
        }
    }
}

-(void)api:(PAApi*)api name:(NSString*)apiName changeTo:(NSString*)newApiName
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    
    for (NSString *k in [self.mapping.beanMapping allKeys])
    {
        NSString *v = [self.mapping.beanMapping objectForKey:k];
        if (![k hasPrefix:apiName])
        {
            [md setObject:v forKey:k];
            continue ;
        }
        
        NSArray *tmp = [k componentsSeparatedByString:@"/"];
        
        NSMutableString *ms = [NSMutableString stringWithCapacity:50];
        [ms appendFormat:@"%@", newApiName];
        for (int i=1; i<tmp.count; i++)
        {
            [ms appendFormat:@"/%@", [tmp objectAtIndex:i]];
        }
        
        [md setObject:v forKey:ms];
        for (int i=0; i<self.beans.allChildren.count; i++)
        {
            PABean *b = [self.beans.allChildren objectAtIndex:i];
            NSMutableArray *newMappings = [NSMutableArray arrayWithCapacity:10];
            
            for (int j=0; j<b.mappings.count; j++)
            {
                NSString *bmk = [b.mappings objectAtIndex:j];
                if ([bmk isEqualToString:k])
                {
                    [newMappings addObject:ms];
                }
                else
                {
                    [newMappings addObject:bmk];
                }
            }
            [b.mappings setArray:newMappings];
        }
    }
    
    [self.mapping.beanMapping removeAllObjects];
    [self.mapping.beanMapping addEntriesFromDictionary:md];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_MAPPING_CHANGED object:md];
}

//common param
-(PAParam*)defaultGetParam
{
    PAParam *param = [[PAParam alloc] init];
    param.method = @"Get";
    param.name = [self newParamValueByValue:@"Param" forKey:@"name" isPost:NO];
    param.paramKey = [self newParamValueByValue:@"Key" forKey:@"paramKey" isPost:NO];
    param.paramValue = @"Value";
    param.paramType = PAPARAM_TYPE_STRING;
    return [param autorelease];
}

-(PAParam*)defaultPostParam
{
    PAParam *param = [[PAParam alloc] init];
    param.name = [self newParamValueByValue:@"Param" forKey:@"name" isPost:YES];
    param.paramKey = [self newParamValueByValue:@"Key" forKey:@"paramKey" isPost:YES];
    param.paramValue = @"Value";
    param.method = @"Post";
    param.paramType = PAPARAM_TYPE_STRING;
    return [param autorelease];
}

-(NSString*)newParamValueByValue:(NSString*)value forKey:(NSString*)key isPost:(BOOL)isPost
{
    NSMutableString *ms = [NSMutableString stringWithString:value];
    int i=1;
    while ([self paramValueExists:ms forKey:key isPost:isPost])
    {
        [ms setString:[NSString stringWithFormat:@"%@_%d", value, i]];
        i++;
    }
    return ms;
}

-(BOOL)paramValueExists:(NSString*)value forKey:(NSString*)key isPost:(BOOL)isPost
{
    NSArray *params = nil;
    if (isPost) {
        params = self.commonPostDatas;
    }
    else
    {
        params = self.commonGetParams;
    }
    
    for (int i=0; i<params.count; i++)
    {
        PAParam *param = [params objectAtIndex:i];
        NSString *pvalue = [param valueForKey:key];
        
        if ([value isEqualToString:pvalue])
        {
            return YES;
        }
    }
    return NO;
}

-(void)insertParams:(NSArray *)array isPost:(BOOL)isPost
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:10];
    if (isPost) {
        [tmp setArray:self.commonPostDatas];
    }
    else
    {
        [tmp setArray:self.commonGetParams];
    }
    
    for (int i=0; i<array.count; i++)
    {
        PAParam *p = [array objectAtIndex:i];
        if (p.rowIndex > tmp.count) {
            [indexSet addIndex:tmp.count];
        }
        else
        {
            [indexSet addIndex:p.rowIndex];
        }
        p.name = [PAObject object:p valueByValue:p.name forKey:@"name" existsObjects:tmp];
        p.paramKey = [PAObject object:p valueByValue:p.paramKey forKey:@"paramKey" existsObjects:tmp];
        [tmp addObject:p];
    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeParams:array isPost:isPost];
    if (isPost) {
        [self.commonPostDatas insertObjects:array atIndexes:indexSet];
    }
    else
    {
        [self.commonGetParams insertObjects:array atIndexes:indexSet];
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          array, @"params",
                          @"insert", @"operation",
                          indexSet, @"indexSet",
                          @"param", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_PARAMS_CHANGED object:dict];
}

-(void)removeParams:(NSArray *)array isPost:(BOOL)isPost
{
    //    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    //    for (int i=0; i<array.count; i++)
    //    {
    //        PAParam *p = [array objectAtIndex:i];
    //        [indexSet addIndex:p.rowIndex];
    //    }
    
    NSIndexSet *indexSet = nil;
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] insertParams:array isPost:isPost];
    if (isPost) {
        indexSet = [PAObject indexesForObjects:array inArray:self.commonPostDatas];
        [self.commonPostDatas removeObjectsAtIndexes:indexSet];
    }
    else
    {
        indexSet = [PAObject indexesForObjects:array inArray:self.commonGetParams];
        [self.commonGetParams removeObjectsAtIndexes:indexSet];
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          array, @"params",
                          @"remove", @"operation",
                          indexSet, @"indexSet",
                          @"param", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_PROJECT_PARAMS_CHANGED object:dict];
}

-(BOOL)paramExists:(PAParam*)param isPost:(BOOL)isPost
{
    NSArray *params = nil;
    if (isPost)
    {
        params = self.commonGetParams;
    }
    else
    {
        params = self.commonPostDatas;
    }
    
    for (int i=0; i<params.count; i++)
    {
        PAParam *p = [params objectAtIndex:i];
        if ([param.paramKey isEqualToString:p.paramKey])
        {
            return YES;
        }
    }
    
    return NO;
}
@end
