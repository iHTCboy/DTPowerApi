//
//  PAApi.h
//  PowerApi
//
//  Created by leks on 12-7-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PAObject.h"
#import "PANetworkManager.h"

#define PAAPI_REQUEST_FINISHED_NOTIFICATION @"PAAPI_REQUEST_FINISHED_NOTIFICATION"

@class PAParam;
@class PAProject;
@class PAApiResult;
@class PAParamGroup;

typedef NS_ENUM(NSInteger, PAApiStatus)
{
    PAApiStatusNormal = 0,
    PAApiStatusRunning,
    PAApiStatusSuccess,
    PAApiStatusFailed
};

@interface PAApi : PAObject<NetworkProtocol>
{
    NSString *url;
    NSString *path;
    NSString *method;
    NSString *exportPrefix;
    NSString *macroName;
    
    NSStringEncoding encoding;

    NSMutableAttributedString *log;
    NSAttributedString *logText;
    
    NSMutableArray *results;
    NSMutableArray *paramGroups;

    PAProject *project;
    NSMutableArray *fields;
    NSMutableArray *beanFields;
    
    NSMutableDictionary *synTableMapping;
    
    PAApiResult *selectedResult;
    PAParamGroup *selectedParamGroup;
    
    NSString *lastSelectedResultIndex;
    NSString *lastSelectedParamGroup;
    
    NSString *autoCreateNewResult;
    NSString *dupSelectedGroup;
    
    PAApiStatus status;
    
    NetworkHeader *requestHeader;
    
    NSString *lastSelectedRow;
    NSString *lastSelectedGroup;
}
//base url
@property (nonatomic, copy) NSString *url;
//subpath for
@property (nonatomic, copy) NSString *path;
//may be filename 
@property (nonatomic, copy) NSString *method;

@property (nonatomic, copy) NSString *exportPrefix;

@property (nonatomic, copy) NSString *macroName;

//encoding particular for api
@property (nonatomic) NSStringEncoding encoding;

//terminal log
@property (nonatomic, retain) NSMutableAttributedString *log;

@property (nonatomic, retain) NSAttributedString *logText;

//results for each requests
@property (nonatomic, retain) NSMutableArray *results;

//params groups
@property (nonatomic, retain) NSMutableArray *paramGroups;

//parent project
@property (nonatomic, assign) PAProject *project;

//feilds returned from request
@property (nonatomic, retain) NSMutableArray *fields;

//fields after mapping to bean
@property (nonatomic, retain) NSMutableArray *beanFields;

//for synchronizing bean table and json table expanding
@property (nonatomic, retain) NSMutableDictionary *synTableMapping;

//for presenting table expandation state
@property (nonatomic, retain) NSMutableArray *expandedItems;

//record last result table offset
@property (nonatomic, retain) NSString *lastResultYOffset;

//selected result
@property (nonatomic, retain) PAApiResult *selectedResult;

//selected param group
@property (nonatomic, retain) PAParamGroup *selectedParamGroup;

//for presenting
@property (nonatomic, copy) NSString *lastSelectedResultIndex;

//for presenting
@property (nonatomic, copy) NSString *lastSelectedParamGroup;

@property (nonatomic, copy) NSString *autoCreateNewResult;
@property (nonatomic, copy) NSString *dupSelectedGroup;

@property (nonatomic) PAApiStatus status;
@property (nonatomic, retain) NetworkHeader *requestHeader;

-(NSString*)requestUrlString;

-(BOOL)start;
-(void)cancel;

-(void)reloadMappingFields;

-(PAParamGroup*)defaultParamGroup:(BOOL)duplicate;
-(PAApiResult*)defaultApiResult;

-(void)insertParamGroups:(NSArray *)array;
-(void)removeParamGroups:(NSArray *)array;
-(void)insertResults:(NSArray *)array;
-(void)removeResults:(NSArray *)array;

-(void)switchResult:(PAApiResult*)result;

-(void)clearLog;

-(NSString*)newResultValueByValue:(NSString*)value forKey:(NSString*)key;
-(NSString*)newParamGroupValueByValue:(NSString*)value forKey:(NSString*)key;

+(NSAttributedString*)attributedString:(NSString*)str color:(NSColor*)color bold:(BOOL)bold;
+(NSAttributedString*)attributedString:(NSString*)str color:(NSColor*)color fontSize:(CGFloat)fontSize bold:(BOOL)bold;
@end
