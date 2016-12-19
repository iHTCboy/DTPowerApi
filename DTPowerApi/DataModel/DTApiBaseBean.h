//
//  DTApiBaseBean.h
//  DTApi
//
//  Created by leks on 13-2-18.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DTAPI_DICT_ASSIGN_STRING(property_name, default_value)\
{\
id obj=[dict objectForKey:@#property_name];\
if([obj isKindOfClass:[NSString class]]) self.property_name = obj;\
else self.property_name = default_value;\
}\

#define DTAPI_DICT_ASSIGN_NUMBER(property_name, default_value)\
{\
id obj=[dict objectForKey:@#property_name];\
NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init]; \
if([obj isKindOfClass:[NSNumber class]]) self.property_name = obj;\
else self.property_name = [formatter numberFromString:default_value];\
}\

#define DTAPI_DICT_ASSIGN_ARRAY_BASICTYPE(property_name)\
{\
self.property_name = [NSMutableArray arrayWithCapacity:10];\
id obj=[dict objectForKey:@#property_name];\
if([obj isKindOfClass:[NSArray class]]) \
{\
[self.property_name setArray:obj];\
}\
}\

@interface DTApiBaseBean : NSObject

+(id)objectForKey:(NSString*)key inDictionary:(NSDictionary*)dict withClass:(Class)objClass;
+(NSMutableArray*)arrayForKey:(NSString*)key inDictionary:(NSDictionary*)dict withClass:(Class)objClass;
@end
