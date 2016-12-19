//
//  PABean.h
//  PowerApi
//
//  Created by leks on 12-7-24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PAObject.h"

@class PAProject;
@class PAProperty;
@class PAField;

typedef enum _PABEAN_LINK_STATUS {
    PABEAN_LINK_STATUS_UNDEFINED,
    PABEAN_LINK_STATUS_LINKSUCCESS,
    PABEAN_LINK_STATUS_LINKFAILED
}PABEAN_LINK_STATUS;

#define PABEAN_STATUS_DESCS [NSArray arrayWithObjects:@"Undefined", @"Link Success", @"Link Fail", nil]

#define PABEAN_TYPE_OBJECT @"Object"
#define PABEAN_TYPE_ARRAY @"Array"
#define PABEAN_TYPE_DICTIONARY @"Dictionary"

@interface PABean : PAObject
{
    NSString *beanType;
    NSString *beanName;
    
    NSString *mappingKey;
    NSString *index;
    
    NSInteger linkStatus;
    NSString *linkStatusDesc;
    
    NSMutableArray *properties;
    
    PAProject *project;
    
    NSMutableArray *mappings;
}

//one of Object, Array
@property (nonatomic, copy) NSString *beanType;

//name for 
@property (nonatomic, copy) NSString *beanName;

//example, the return string:{"id":"1", "obj":{"beanA":{}}}
//if the bean maps to "beanA", the key should be:"_paroot_::obj::bean"
@property (nonatomic, copy) NSString *mappingKey;

//used in array
@property (nonatomic, copy) NSString *index;

//one of link success, not link, link failed
@property (nonatomic) NSInteger linkStatus;

//one of link success, not link, link failed
@property (nonatomic, copy) NSString *linkStatusDesc;

//fields
@property (nonatomic, retain) NSMutableArray *properties;

//parent project
@property (nonatomic, assign) PAProject *project;

@property (nonatomic, retain) NSMutableArray *mappings;

-(PAProperty*)defaultProperty;
-(PAProperty*)addPropertyByField:(PAField*)field;
-(NSDictionary*)copyDict;

-(BOOL)hasPropertyField:(PAField*)field;

-(BOOL)propertyValueExists:(NSString*)value forKey:(NSString*)key;
-(NSString*)newPropertyValueByValue:(NSString*)value forKey:(NSString*)key except:(PAProperty*)eproperty;

-(BOOL)validateBeanName:(NSString*)beanname;
-(void)removeProperties:(NSArray *)array;
-(void)insertProperties:(NSArray *)array;

//-(NSString*)newPropertyValueByValue:(NSString*)value forKey:(NSString*)key except:(PAProperty*)eproperty;
-(void)addMappingKey:(NSString*)k;
-(void)removeMappingKey:(NSString*)k;
@end
