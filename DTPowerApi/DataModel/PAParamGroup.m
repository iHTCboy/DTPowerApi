//
//  PAParamGroup.m
//  DTPowerApi
//
//  Created by leks on 13-2-27.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAParamGroup.h"
#import "PAApi.h"
#import "DTUtil.h"
#import "PAParam.h"
#import "Global.h"

@implementation PAParamGroup
@synthesize getParams;
@synthesize postDatas;
@synthesize parentApi;

-(void)dealloc
{
    [getParams release];
    [postDatas release];
    [super dealloc];
}

-(id)init
{
    if (self = [super init])
    {
        self.type = PAOBJECT_NAME_PARAMGROUP;
        self.typeName = PAOBJECT_NAME_PARAMGROUP;
        self.getParams = [NSMutableArray arrayWithCapacity:10];
        self.postDatas = [NSMutableArray arrayWithCapacity:10];
    }
    
    return self;
}

-(NSDictionary*)toDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    [md setDictionary:[super toDict]];
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
    for (int i=0; i<getParams.count; i++)
    {
        PAParam *param = [getParams objectAtIndex:i];
        [ma addObject:[param toDict]];
    }
    [md setObject:ma forKey:@"getParams"];
    
    ma = [NSMutableArray arrayWithCapacity:10];
    for (int i=0; i<postDatas.count; i++)
    {
        PAParam *param = [postDatas objectAtIndex:i];
        [ma addObject:[param toDict]];
    }
    
    [md setObject:ma forKey:@"postDatas"];
    
    return md;
}


-(id)initWithDict:(NSDictionary*)dict
{
    if (self = [super initWithDict:dict])
    {
        self.type = PAOBJECT_NAME_PARAMGROUP;
        self.typeName = PAOBJECT_NAME_PARAMGROUP;
        
        NSArray *tmpParams = [dict objectForKey:@"getParams"];
        NSArray *tmpDatas = [dict objectForKey:@"postDatas"];
        
        self.getParams = [NSMutableArray arrayWithCapacity:10];
        for (int i=0; i<tmpParams.count; i++)
        {
            NSDictionary *tmpParam = [tmpParams objectAtIndex:i];
            PAParam *pa = [[PAParam alloc] initWithDict:tmpParam];
            pa.rowIndex = i;
            [self.getParams addObject:pa];
            [pa release];
        }
        
        self.postDatas = [NSMutableArray arrayWithCapacity:10];
        for (int i=0; i<tmpDatas.count; i++)
        {
            NSDictionary *tmpParam = [tmpDatas objectAtIndex:i];
            PAParam *pa = [[PAParam alloc] initWithDict:tmpParam];
            pa.rowIndex = i;
            [self.postDatas addObject:pa];
            [pa release];
        }
    }
    
    return self;
}

-(PAParam*)defaultGetParam
{
    PAParam *param = [[PAParam alloc] init];
    param.name = [self newParamValueByValue:@"Param" forKey:@"name" isPost:NO];
    param.paramKey = [self newParamValueByValue:@"Key" forKey:@"paramKey" isPost:NO];
    param.paramValue = @"Value";
    param.method = PAPARAM_METHOD_GET;
    param.paramType = PAPARAM_TYPE_STRING;
    param.parentGroup = self;
    return [param autorelease];
}

-(PAParam*)defaultPostParam
{
    PAParam *param = [[PAParam alloc] init];
    param.name = [self newParamValueByValue:@"Param" forKey:@"name" isPost:YES];
    param.paramKey = [self newParamValueByValue:@"Key" forKey:@"paramKey" isPost:YES];
    param.paramValue = @"Value";
    param.method = PAPARAM_METHOD_POST;
    param.paramType = PAPARAM_TYPE_STRING;
    param.parentGroup = self;
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
        params = self.postDatas;
    }
    else
    {
        params = self.getParams;
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
        [tmp setArray:self.postDatas];
    }
    else
    {
        [tmp setArray:self.getParams];
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
        p.parentGroup = self;
        [tmp addObject:p];
    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeParams:array isPost:isPost];
    if (isPost) {
        [self.postDatas insertObjects:array atIndexes:indexSet];
    }
    else
    {
        [self.getParams insertObjects:array atIndexes:indexSet];
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.parentApi, @"object",
                          array, @"params",
                          @"insert", @"operation",
                          indexSet, @"indexSet",
                          @"param", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_API_CHILDREN_CHANGED object:dict];
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
        indexSet = [PAObject indexesForObjects:array inArray:self.postDatas];
        [self.postDatas removeObjectsAtIndexes:indexSet];
    }
    else
    {
        indexSet = [PAObject indexesForObjects:array inArray:self.getParams];
        [self.getParams removeObjectsAtIndexes:indexSet];
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.parentApi, @"object",
                          array, @"params",
                          @"remove", @"operation",
                          indexSet, @"indexSet",
                          @"param", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_API_CHILDREN_CHANGED object:dict];
}

//-(void)setValue:(id)value forKey:(NSString *)key
//{
//    
//}

-(id)copyWithZone:(NSZone *)zone
{
    PAParamGroup *pg = [super copyWithZone:zone];
    if (pg) {
        pg.parentApi = self.parentApi;
        pg.getParams = [[[NSMutableArray alloc] initWithArray:self.getParams copyItems:YES] autorelease];
        pg.postDatas = [[[NSMutableArray alloc] initWithArray:self.postDatas copyItems:YES] autorelease];
    }
    
    return pg;
}
@end
