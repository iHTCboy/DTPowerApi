//
//  PAProject.h
//  PowerApi
//
//  Created by leks on 12-7-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PAObject.h"
#import "PAApiFolder.h"
#import "PABeanFolder.h"
#import "PAMapping.h"

@class PAField;
@class PAParam;

@interface PAProject : PAObject
{
    NSString *baseUrl;
    NSString *websiteUrl;
    NSStringEncoding encoding;
    
    PAApiFolder *apis;
    PABeanFolder *beans;
    PAMapping *mapping;
    
    NSArray *allProjectsRefs;
    NSMutableArray *commonGetParams;
    NSMutableArray *commonPostDatas;
}

//base url for whole project
@property (nonatomic, copy) NSString *baseUrl;

//such as supported website url
@property (nonatomic, copy) NSString *websiteUrl;

//encoding for whole project
@property (nonatomic) NSStringEncoding encoding;

//api array wrapper
@property (nonatomic, retain) PAApiFolder *apis;

//bean array wrapper
@property (nonatomic, retain) PABeanFolder *beans;

//internal datas used for mapping json to bean
@property (nonatomic, retain) PAMapping *mapping;

@property (nonatomic, assign) NSArray *allProjectsRefs;

@property (nonatomic, retain) NSMutableArray *commonGetParams;

@property (nonatomic, retain) NSMutableArray *commonPostDatas;

-(PABean*)beanForMappingKey:(NSString*)mappingKey;
-(PABean*)beanFormName:(NSString*)beanName;
-(void)addMapping:(NSString*)mappingKey forBeanName:(NSString*)beanName;
-(void)removeMapping:(NSString*)mappingKey forBeanName:(NSString*)beanName;

+(NSMutableArray*)projectsForDictionary:(NSDictionary*)dict;

-(BOOL)isBeanType:(PAField*)field;
-(NSArray*)beanNames;

/*
 
 */
-(NSString*)bean:(PABean*)bean valueByValue:(NSString*)value forKey:(NSString*)key;
-(NSString*)api:(PAApi*)api valueByValue:(NSString*)value forKey:(NSString*)key;

-(PAParam*)defaultGetParam;
-(PAParam*)defaultPostParam;
-(void)insertParams:(NSArray *)array isPost:(BOOL)isPost;
-(void)removeParams:(NSArray *)array isPost:(BOOL)isPost;
-(BOOL)paramExists:(PAParam*)param isPost:(BOOL)isPost;

-(NSString*)newParamValueByValue:(NSString*)value forKey:(NSString*)key isPost:(BOOL)isPost;
/*
 for undo
 */
-(void)insertBeans:(NSArray *)array;
-(void)removeBeans:(NSArray *)array;
-(void)insertApis:(NSArray *)array;
-(void)removeApis:(NSArray *)array;

-(void)bean:(PABean*)bean name:(NSString*)beanName changeTo:(NSString*)newBeanName;
-(void)api:(PAApi*)api name:(NSString*)apiName changeTo:(NSString*)newApiName;


@end
