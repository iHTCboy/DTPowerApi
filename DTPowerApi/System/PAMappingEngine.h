//
//  PAMappingEngine.h
//  DTPowerApi
//
//  Created by leks on 13-1-24.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PAField.h"

@class PAProject;
@class PABean;

@interface PAMappingEngine : NSObject


+(NSMutableArray*)generateFieldsByJsonString:(NSString*)jsonString forApi:(NSString*)apiName;
//+(NSMutableArray*)genarateMappingFieldsByFields:(NSArray*)jsonFields;

+(NSMutableArray*)propertyFieldsFromJsonFields:(NSArray*)jsonFields inProject:(PAProject*)project inApi:(NSString*)apiName;

+(void)combineJsonField:(PAField*)jsonField withBeanField:(PAField*)beanField inProject:(PAProject*)project;

+(BOOL)canCreateFromJsonField:(PAField*)jsonField toBeanField:(PAField*)beanField inProject:(PAProject*)project;
+(BOOL)canMapFromJsonField:(PAField*)jsonField toBeanField:(PAField*)beanField inProject:(PAProject*)project;
+(BOOL)canSmartMapFromJsonField:(PAField*)jsonField toBeanField:(PAField*)beanField inProject:(PAProject*)project;
+(BOOL)canDeleteMapFromBeanField:(PAField*)beanField inProject:(PAProject*)project;

+(BOOL)mapJsonField:(PAField*)jsonField toBeanField:(PAField*)beanField inProject:(PAProject*)project forceCreate:(BOOL)forceCreate;

+(PABean*)bestBeanForField:(PAField*)field inProject:(PAProject*)project;
+(CGFloat)countMatchingRateForField:(PAField*)field withBean:(PABean*)bean;

+(PABean*)createBeanForJsonField:(PAField*)jsonField inProject:(PAProject*)project toTmpArray:(NSMutableArray*)tmpArray;
+(PABean*)createBeanForDictionary:(NSDictionary*)dict withKey:(NSString*)key inProject:(PAProject*)project toTmpArray:(NSMutableArray*)tmpArray;
+(BOOL)smartMapJsonField:(PAField*)jsonField toBeanField:(PAField*)beanField inProject:(PAProject*)project;
@end
