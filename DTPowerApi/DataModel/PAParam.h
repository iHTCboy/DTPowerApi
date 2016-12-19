//
//  PAParam.h
//  PowerApi
//
//  Created by leks on 12-7-24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PAObject.h"

#define PAPARAM_TYPE_STRING @"String"
#define PAPARAM_TYPE_NUMBER @"Number"
#define PAPARAM_TYPE_FILE @"File"

#define PAPARAM_METHOD_GET @"Get"
#define PAPARAM_METHOD_POST @"Post"

#define PAPARAM_CONTENTTYPES [NSArray arrayWithObjects:@"", @"", @"", nil]
@class PAParamGroup;

@interface PAParam : PAObject
{
    NSString *paramType;
    NSString *paramKey;
    NSString *filename;
    
    NSString *paramValue;
    NSString *method;
    
    //post only
    NSString *contentType;
    PAParamGroup *parentGroup;
}

//param type such String, Number, File
@property (nonatomic, copy) NSString *paramType;

//param key
@property (nonatomic, copy) NSString *paramKey;

//optional, if post file
@property (nonatomic, copy) NSString *filename;

//Get or Post
@property (nonatomic, copy) NSString *method;

//one of String, Integer, Binary data, 
@property (nonatomic, copy) NSString *paramValue;

//for post data
@property (nonatomic, copy) NSString *contentType;

@property (nonatomic, assign) PAParamGroup *parentGroup;

+(NSDictionary*)parseUrlString:(NSString*)url;
@end
