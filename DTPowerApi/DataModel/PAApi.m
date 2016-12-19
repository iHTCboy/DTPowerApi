//
//  PAApi.m
//  PowerApi
//
//  Created by leks on 12-7-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PAApi.h"
#import "DTUtil.h"
#import "JSON.h"
#import "PAParam.h"
#import "Global.h"
#import "PAProject.h"
#import "PAMappingEngine.h"
#import "PAApiResult.h"
#import "PAParamGroup.h"
#import "GTMBase64.h"

#define LOG_COLOR_SUCCESS [NSColor colorWithDeviceRed:64.0f/255.0f green:180.0f/255.0f blue:96.0f/255.0f alpha:1.0]
#define LOG_COLOR_FAIL [NSColor colorWithDeviceRed:160.0f/255.0f green:20.0f/255.0f blue:35.0f/255.0f alpha:1.0]
#define LOG_COLOR_CANCEL [NSColor colorWithDeviceRed:212.0f/255.0f green:147.0f/255.0f blue:90.0f/255.0f alpha:1.0]

@implementation PAApi
@synthesize url;
@synthesize path;
@synthesize method;
@synthesize exportPrefix;
@synthesize macroName;
@synthesize encoding;
@synthesize log;
@synthesize results;
@synthesize paramGroups;
@synthesize project;
@synthesize fields;
@synthesize beanFields;
@synthesize synTableMapping;
@synthesize expandedItems;
@synthesize lastResultYOffset;
@synthesize selectedResult;
@synthesize selectedParamGroup;
@synthesize lastSelectedResultIndex;
@synthesize lastSelectedParamGroup;
@synthesize autoCreateNewResult;
@synthesize dupSelectedGroup;
@synthesize status;
@synthesize logText;
@synthesize requestHeader;

-(void)dealloc
{
    [url release];
    [path release];
    [method release];
    [exportPrefix release];
    [macroName release];
    [log release];
    [results release];
    [paramGroups release];
    [fields release];
    [beanFields release];
    [synTableMapping release];
    [expandedItems release];
    [lastResultYOffset release];
    [selectedResult release];
    [selectedParamGroup release];
    [lastSelectedResultIndex release];
    [lastSelectedParamGroup release];
    [autoCreateNewResult release];
    [dupSelectedGroup release];
    [logText release];
    [requestHeader release];
    [super dealloc];
}

-(id)init
{
    if (self = [super init]) 
    {
        self.type = PAOBJECT_NAME_API;
        self.typeName = PAOBJECT_NAME_API;
        self.desc = PAOBJECT_DESC_API;
        self.log = [[[NSMutableAttributedString alloc] init] autorelease];
        self.logText = self.log;
        self.synTableMapping = [NSMutableDictionary dictionaryWithCapacity:100];
        self.expandedItems = [NSMutableArray arrayWithCapacity:10];
        self.results = [NSMutableArray arrayWithCapacity:10];
        self.lastSelectedResultIndex = @"0";
        self.lastSelectedParamGroup = @"0";
        self.paramGroups = [NSMutableArray arrayWithCapacity:10];
        PAParamGroup *pg = [self defaultParamGroup:NO];
        [self.paramGroups addObject:pg];
        self.selectedParamGroup = pg;
        self.autoCreateNewResult = @"0";
        self.dupSelectedGroup = @"1";
        self.path = @"";
        self.exportPrefix = @"";
        self.macroName = @"";
        
        status = PAApiStatusNormal;
    }
    return self;
}

-(NSDictionary*)toDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    [md setDictionary:[super toDict]];
    
    DICT_EXPORT1(url);
    DICT_EXPORT1(path);
    DICT_EXPORT1(method);
    DICT_EXPORT1(exportPrefix);
    DICT_EXPORT1(macroName);
    
//    DICT_EXPORT1(log);
    if (self.log) {
        NSRange r = NSMakeRange(0, self.log.string.length);
        NSData *logData = [self.log RTFFromRange:r documentAttributes:nil];
        NSString *attributeBase64Log = [GTMBase64 stringByEncodingData:logData];
        [md setObject:attributeBase64Log forKey:@"log"];
    }
    
    
    DICT_EXPORT1(lastResultYOffset);
    DICT_EXPORT1(lastSelectedResultIndex);
    DICT_EXPORT1(lastSelectedParamGroup);
    DICT_EXPORT1(autoCreateNewResult);
    DICT_EXPORT1(dupSelectedGroup);
    DICT_EXPORT1(lastSelectedRow);
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
    
    ma = [NSMutableArray arrayWithCapacity:10];
    for (int i=0; i<self.results.count; i++) {
        PAApiResult *result = [self.results objectAtIndex:i];
        [ma addObject:[result toDict]];
    }
    
    [md setObject:ma forKey:@"results"];
    
    ma = [NSMutableArray arrayWithCapacity:10];
    for (int i=0; i<self.paramGroups.count; i++) {
        PAParamGroup *pg = [self.paramGroups objectAtIndex:i];
        [ma addObject:[pg toDict]];
    }
    
    [md setObject:ma forKey:@"paramGroups"];
    
    [md setObject:expandedItems forKey:@"expandedItems"];
    [md setObject:[NSString stringWithFormat:@"%ld", status] forKey:@"status"];
    
    return md;
}

-(id)initWithDict:(NSDictionary*)dict
{
    if (self = [super initWithDict:dict])
    {
        self.type = PAOBJECT_NAME_API;
        self.typeName = PAOBJECT_NAME_API;
        self.desc = PAOBJECT_DESC_API;
        self.synTableMapping = [NSMutableDictionary dictionaryWithCapacity:100];
        self.expandedItems = [NSMutableArray arrayWithCapacity:10];
        
        DICT_ASSIGN1(url);
        DICT_ASSIGN1(path);
        DICT_ASSIGN1(method);
        DICT_ASSIGN1(exportPrefix);
        DICT_ASSIGN1(macroName);
        DICT_ASSIGN1(lastResultYOffset);
        DICT_ASSIGN1(lastSelectedResultIndex);
        DICT_ASSIGN1(lastSelectedParamGroup);
        DICT_ASSIGN1(autoCreateNewResult);
        DICT_ASSIGN1(dupSelectedGroup);
        
        NSString *attributeBase64Log = [dict objectForKey:@"log"];
        if (attributeBase64Log)
        {
            NSData *logData = [GTMBase64 decodeString:attributeBase64Log];
            if (logData)
            {
                self.log = [[[NSMutableAttributedString alloc] initWithRTF:logData documentAttributes:nil] autorelease];
            }
        }
        
        if (!self.log) {
            self.log = [[[NSMutableAttributedString alloc] init] autorelease];
        }
        
        self.logText = self.log;
//        self.log = [NSMutableString stringWithCapacity:1000];
//        if ([dict objectForKey:@"log"])
//        {
//            [self.log setString:[dict objectForKey:@"log"]];
//        }
        
        NSArray *tmpResults = [dict objectForKey:@"results"];
        NSArray *tmpParamGroups = [dict objectForKey:@"paramGroups"];
        
        //results
        self.results = [NSMutableArray arrayWithCapacity:10];
        for (int i=0; i<tmpResults.count; i++)
        {
            
            NSDictionary *tmpResult = [tmpResults objectAtIndex:i];
            PAApiResult *r = [[PAApiResult alloc] initWithDict:tmpResult];
            r.parentApi = self;
            [self.results addObject:r];
            [r release];
        }
        
        if (self.lastSelectedResultIndex.integerValue < self.results.count) {
            self.selectedResult = [self.results objectAtIndex:self.lastSelectedResultIndex.integerValue];
        }
        
        //paramGroups
        self.paramGroups = [NSMutableArray arrayWithCapacity:10];
        for (int i=0; i<tmpParamGroups.count; i++)
        {
            NSDictionary *tmpParamGroup = [tmpParamGroups objectAtIndex:i];
            PAParamGroup *pg = [[PAParamGroup alloc] initWithDict:tmpParamGroup];
            pg.parentApi = self;
            [self.paramGroups addObject:pg];
            [pg release];
        }
        
        if (self.lastSelectedParamGroup.integerValue < self.paramGroups.count) {
            self.selectedParamGroup = [self.paramGroups objectAtIndex:self.lastSelectedParamGroup.integerValue];
        }
        
        id exItems = [dict objectForKey:@"expandedItems"];
        if ([exItems isKindOfClass:[NSArray class]])
        {
            [self.expandedItems setArray:exItems];
        }
        
        NSString *s = [dict objectForKey:@"status"];
        status = s.integerValue;
        if (status == PAApiStatusRunning) {
            status = PAApiStatusFailed;
        }
        [self reloadMappingFields];
        
    }
    
    return self;
}

-(void)setValue:(id)value forKey:(NSString *)key
{
    if ([key isEqualToString:@"name"])
    {
        BOOL exists = [PAObject object:self ValueExists:value forKey:key existsObjects:project.apis.allChildren];
        if (!exists && value && [value length]>0) {
            if ([key isEqualToString:@"name"])
            {
                [project api:self name:self.name changeTo:value];
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
            
            if (!value || [value length] == 0) {
                [md setObject:@"Api name can not be empty!" forKey:@"msg"];
            }
            else
            {
                [md setObject:@"Api name already exists!" forKey:@"msg"];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_OBJECT_VALUE_EXISTS object:md];
        }
    }
    else
    {
        [super setValue:value forKey:key];
    }
}

-(id)copyWithZone:(NSZone *)zone
{
    PAApi *api = [super copyWithZone:zone];
    if (api) {
        api.url = self.url;
        api.path = self.path;
        api.method = self.method;
        api.encoding = self.encoding;
        api.log = [NSMutableString stringWithCapacity:10];
    }
    return api;
}

-(NSString*)requestUrlString
{
    if (self.url.length == 0) {
        return nil;
    }
    
    NSMutableString *ms = [NSMutableString stringWithCapacity:100];
    [ms appendString:self.url];
    [ms replaceOccurrencesOfString:@"${PROJECT_BASEURL}" withString:project.baseUrl options:0 range:NSMakeRange(0, ms.length)];
    
    if (self.path) [ms appendFormat:@"%@", self.path];
    BOOL isFirst = YES;
    
    for (int i=0; i<self.selectedParamGroup.getParams.count; i++)
    {
        PAParam *p = [self.selectedParamGroup.getParams objectAtIndex:i];
        if (i != 0) {
            [ms appendString:@"&"];
        }
    
        [ms appendFormat:@"%@=%@", p.paramKey, p.paramValue];
        isFirst = NO;
    }
    
    for (int i=0; i<self.project.commonGetParams.count; i++)
    {
        PAParam *pp = [self.project.commonGetParams objectAtIndex:i];
        BOOL exists = NO;
        
        for (int j=0; j<self.selectedParamGroup.getParams.count; j++)
        {
            PAParam *p = [self.selectedParamGroup.getParams objectAtIndex:j];
            if ([pp.paramKey isEqualToString:p.paramKey])
            {
                exists = YES ;
            }
        }
        
        if (exists) {
            continue ;
        }
        
        if (!isFirst) {
            [ms appendString:@"&"];
        }
        
        [ms appendFormat:@"%@=%@", pp.paramKey, pp.paramValue];
        isFirst = NO;
    }
    
    return [ms stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

-(BOOL)start
{
    if (status == PAApiStatusRunning) {
        return NO;
    }
    
    //no undo action
    if (autoCreateNewResult.integerValue==1 || self.results.count == 0)
    {
        PAApiResult *result = [self defaultApiResult];
        result.rowIndex = self.results.count;
        result.name = [self newResultValueByValue:@"Result" forKey:@"name"];
        result.parentApi = self;
        
        [self.results addObject:result];
        [self switchResult:result];
        
    }
    else if (!self.selectedResult)
    {
        [self switchResult:[self.results objectAtIndex:0]];
    }

    [self.selectedResult start];
    self.selectedResult.groupName = self.selectedParamGroup.name;
//    self.selectedResult.responseSrcString = @"";
    self.selectedResult.responseStatus = @"";
    self.selectedResult.responseHeaders = @"";
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          @"result", @"type",
                          @"reload", @"operation",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_API_CHILDREN_CHANGED object:dict];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_APIRESULT_SELECTION_CHANGED object:dict];
    
    [self.log appendAttributedString:[PAApi attributedString:@"\n"]];
    [self.log appendAttributedString:[PAApi attributedLogTime]];
    [self.log appendAttributedString:[PAApi attributedString:@"Request started...\n"]];
    [self refreshLog];
    
    [self switchStatus:PAApiStatusRunning];
    self.requestHeader = [gNetworkManager startRequestForApi:self Delg:self];
    
    return YES;
}

-(void)cancel
{
    [gNetworkManager cancelHeader:self.requestHeader];
    
    [self.log appendAttributedString:[PAApi attributedLogTime]];
    [self.log appendAttributedString:[PAApi attributedString:@"Request Canceled...\n" color:LOG_COLOR_CANCEL bold:NO]];
    [self refreshLog];
    [self switchStatus:PAApiStatusNormal];
}

-(void)switchStatus:(PAApiStatus)nStatus
{
    self.status = nStatus;
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_API_STATUS_CHANGED object:self];
}

-(void)test
{
    NSString *p = [[NSBundle mainBundle] pathForResource:@"testdata" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:p];
    
    self.selectedResult.responseJsonString = [dict objectForKey:@"api2"];
    [self reloadMappingFields];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PAAPI_REQUEST_FINISHED_NOTIFICATION object:self];
}

-(void)networkFinished:(NetworkHeader*)header
{
    [self.selectedResult stop];
    ASIHTTPRequest *request = header.request;
    
    NSString *successLog = [NSString stringWithFormat:@"Request success...%@\n", request.responseStatusMessage];
    [self.log appendAttributedString:[PAApi attributedLogTime]];
    [self.log appendAttributedString:[PAApi attributedString:successLog color:LOG_COLOR_SUCCESS bold:NO]];
    [self refreshLog];

    id jsonObj = [request.responseString JSONValue];
    if (!jsonObj) {
        NSString *successLog = [NSString stringWithFormat:@"Json parse failed...\n"];
        [self.log appendAttributedString:[PAApi attributedLogTime]];
        [self.log appendAttributedString:[PAApi attributedString:successLog color:LOG_COLOR_FAIL bold:YES]];
        [self refreshLog];
        [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_API_PARSE_FALED object:nil];
    }
    
    NSMutableString *ms = [NSMutableString stringWithCapacity:2000];
//    [ms appendFormat:@"Response Status:%@\n\n", request.responseStatusMessage];
    
//    [ms appendFormat:@"Response Body:\n\n%@\n\n", request.responseString];
//    [ms appendString:@"Response Headers:\n\n"];
    
    NSArray *hkeys = [request.responseHeaders allKeys];
    for (NSString *k in hkeys)
    {
        [ms appendFormat:@"%@:  %@\n", k, [request.responseHeaders objectForKey:k]];
    }

    self.selectedResult.responseStatus = request.responseStatusMessage;
//    self.selectedResult.responseHeaders = ms;
//    self.selectedResult.responseString = request.responseString;
    
//    self.selectedResult.responseSrcString = request.responseString;
    self.selectedResult.responseJsonString = request.responseString;
    self.selectedResult.responseHeaders = ms;
    
    //test
    [self.expandedItems removeAllObjects];
    [self reloadMappingFields];
    
    
    [self switchStatus:PAApiStatusSuccess];
    [[NSNotificationCenter defaultCenter] postNotificationName:PAAPI_REQUEST_FINISHED_NOTIFICATION object:self];
}

-(void)clearMappingDatas
{
    [self.fields removeAllObjects];
    [self.beanFields removeAllObjects];
    [self.synTableMapping removeAllObjects];
}

-(void)reloadMappingFields
{
    [self clearMappingDatas];
    
    if (self.selectedResult.responseJsonString.length == 0)
    {
        return ;
    }
    
    self.fields = [PAMappingEngine generateFieldsByJsonString:self.selectedResult.responseJsonString forApi:self.name];
    
    self.beanFields = [PAMappingEngine propertyFieldsFromJsonFields:self.fields inProject:self.project inApi:self.name];
    
    for (int i=0; i<self.fields.count; i++)
    {
        PAField *jsonSub = [self.fields objectAtIndex:i];
        PAField *beanSub = [self.beanFields objectAtIndex:i];
        
        [PAMappingEngine combineJsonField:jsonSub withBeanField:beanSub inProject:self.project];
    }
    
    for (int i=0; i<self.fields.count; i++)
    {
        PAField *jsonSub = [self.fields objectAtIndex:i];
        PAField *beanSub = [self.beanFields objectAtIndex:i];
        
        @try {
            [self generateSynTableMapping:beanSub jsonField:jsonSub];
        }
        @catch (NSException *exception) {
            NSLog(@"");
        }
        @finally {
            ;
        }
        
    }
}

-(void)networkFailed:(NetworkHeader*)header
{
    [self.selectedResult stop];
    ASIHTTPRequest *request = header.request;
    
    NSString *failedLog = [NSString stringWithFormat:@"Request failed...%@\n", header.data];
    [self.log appendAttributedString:[PAApi attributedLogTime]];
    [self.log appendAttributedString:[PAApi attributedString:failedLog color:LOG_COLOR_FAIL bold:YES]];
    [self refreshLog];

    NSMutableString *ms = [NSMutableString stringWithCapacity:2000];
    [ms appendFormat:@"Response Status:%@\n\n", request.responseStatusMessage];
    [ms appendString:@"Response Headers:\n\n"];
    
    NSArray *hkeys = [request.responseHeaders allKeys];
    for (NSString *k in hkeys)
    {
        [ms appendFormat:@"%@:  %@\n", k, [request.responseHeaders objectForKey:k]];
    }
    
    [ms appendFormat:@"\nResponse Body:\n\n%@", request.responseString];
//    self.selectedResult.responseSrcString = ms;
    self.selectedResult.responseJsonString = @"";
    self.selectedResult.responseHeaderString = @"";
    
    [self.expandedItems removeAllObjects];
    [self reloadMappingFields];

    [self switchStatus:PAApiStatusFailed];
    [[NSNotificationCenter defaultCenter] postNotificationName:PAAPI_REQUEST_FINISHED_NOTIFICATION object:self];
}

-(void)generateSynTableMapping:(PAField*)beanField jsonField:(PAField*)jsonField
{
//    NSLog(@"bf:%@       jf:%@", beanField.mappingKey, jsonField.mappingKey);
    NSString *beanAddr = [NSString stringWithFormat:@"%p", beanField];
    NSString *jsonAddr = [NSString stringWithFormat:@"%p", jsonField];
    
    [self.synTableMapping setObject:jsonField forKey:beanAddr];
    [self.synTableMapping setObject:beanField forKey:jsonAddr];
    
    for (int i=0; i<beanField.subFields.count; i++)
    {
        PAField *beanSubField = [beanField.subFields objectAtIndex:i];
        PAField *jsonSubField = [jsonField.subFields objectAtIndex:i];
        
        [self generateSynTableMapping:beanSubField jsonField:jsonSubField];
    }
}

-(void)switchResult:(PAApiResult*)result
{
    self.selectedResult = result;
    [self reloadMappingFields];
}

-(void)clearLog
{
    self.log = [[[NSMutableAttributedString alloc] init] autorelease];
    [self refreshLog];
}

-(void)refreshLog
{
    self.logText = nil;
    self.logText = self.log;
}
#pragma mark -
#pragma mark insert methods

-(PAParamGroup*)defaultParamGroup:(BOOL)duplicate
{
    PAParamGroup *pg = nil;
    if (duplicate) {
        pg = [[self.selectedParamGroup copy] autorelease];
        pg.name = [self newParamGroupValueByValue:pg.name forKey:@"name"];
        pg.parentApi = self;
    }
    else
    {
        pg = [[[PAParamGroup alloc] init] autorelease];
        pg.name = [self newParamGroupValueByValue:@"Group" forKey:@"name"];
        pg.parentApi = self;
    }
    
    return pg;
}

-(NSString*)newParamGroupValueByValue:(NSString*)value forKey:(NSString*)key
{
    NSMutableString *ms = [NSMutableString stringWithString:value];
    int i=1;
    while ([self paramValueExists:ms forKey:key])
    {
        [ms setString:[NSString stringWithFormat:@"%@_%d", value, i]];
        i++;
    }
    return ms;
}

-(BOOL)paramValueExists:(NSString*)value forKey:(NSString*)key
{
    for (int i=0; i<self.paramGroups.count; i++)
    {
        PAParamGroup *pg = [paramGroups objectAtIndex:i];
        NSString *pvalue = [pg valueForKey:key];
        
        if ([value isEqualToString:pvalue])
        {
            return YES;
        }
    }
    return NO;
}

-(PAApiResult*)defaultApiResult
{
    PAApiResult *result = [[PAApiResult alloc] init];
    result.name = [self newResultValueByValue:@"Result" forKey:@"name"];
    result.parentApi = self;
    result.groupName = self.selectedParamGroup.name;
    
    return [result autorelease];
}

-(NSString*)newResultValueByValue:(NSString*)value forKey:(NSString*)key
{
    NSMutableString *ms = [NSMutableString stringWithString:value];
    int i=1;
    while ([self resultValueExists:ms forKey:key])
    {
        [ms setString:[NSString stringWithFormat:@"%@_%d", value, i]];
        i++;
    }
    return ms;
}

-(BOOL)resultValueExists:(NSString*)value forKey:(NSString*)key
{
    for (int i=0; i<self.results.count; i++)
    {
        PAApiResult *r = [self.results objectAtIndex:i];
        NSString *pvalue = [r valueForKey:key];
        
        if ([value isEqualToString:pvalue])
        {
            return YES;
        }
    }
    return NO;
}

-(void)insertParamGroups:(NSArray *)array
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:10];
    [tmp setArray:self.paramGroups];
    
    for (int i=0; i<array.count; i++)
    {
        PAParamGroup *pg = [array objectAtIndex:i];
        if (pg.rowIndex > tmp.count) {
            [indexSet addIndex:tmp.count];
        }
        else
        {
            [indexSet addIndex:pg.rowIndex];
        }
        pg.name = [PAObject object:pg valueByValue:pg.name forKey:@"name" existsObjects:tmp];
        pg.parentApi = self;
        [tmp addObject:pg];
    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeParamGroups:array];
    [self.paramGroups insertObjects:array atIndexes:indexSet];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          array, @"paramGroups",
                          @"insert", @"operation",
                          indexSet, @"indexSet",
                          @"paramGroup", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_API_CHILDREN_CHANGED object:dict];
}

-(void)removeParamGroups:(NSArray *)array
{
    NSIndexSet *indexSet = [PAObject indexesForObjects:array inArray:self.paramGroups];
//    for (int i=0; i<array.count; i++)
//    {
//        PAParamGroup *pg = [array objectAtIndex:i];
//        [indexSet addIndex:pg.rowIndex];
//    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] insertParamGroups:array];
    [self.paramGroups removeObjectsAtIndexes:indexSet];

    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          array, @"paramGroups",
                          @"remove", @"operation",
                          indexSet, @"indexSet",
                          @"paramGroup", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_API_CHILDREN_CHANGED object:dict];
}

-(void)insertResults:(NSArray *)array
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:10];
    [tmp setArray:self.results];
    
    for (int i=0; i<array.count; i++)
    {
        PAApiResult *r = [array objectAtIndex:i];
        if (r.rowIndex > tmp.count) {
            [indexSet addIndex:tmp.count];
        }
        else
        {
            [indexSet addIndex:r.rowIndex];
        }
        r.name = [PAObject object:r valueByValue:r.name forKey:@"name" existsObjects:tmp];
        r.parentApi = self;
        [tmp addObject:r];
    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeResults:array];
    [self.results insertObjects:array atIndexes:indexSet];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          array, @"results",
                          @"insert", @"operation",
                          indexSet, @"indexSet",
                          @"result", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_API_CHILDREN_CHANGED object:dict];
    
}

-(void)removeResults:(NSArray *)array
{
    NSIndexSet *indexSet = [PAObject indexesForObjects:array inArray:self.results];
//    for (int i=0; i<array.count; i++)
//    {
//        PAApiResult *r = [array objectAtIndex:i];
//        [indexSet addIndex:r.rowIndex];
//    }
    
    NSUndoManager *undoManager = [GlobalSetting undoManager];
    [[undoManager prepareWithInvocationTarget:self] insertResults:array];
    [self.results removeObjectsAtIndexes:indexSet];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"object",
                          array, @"results",
                          @"remove", @"operation",
                          indexSet, @"indexSet",
                          @"result", @"type",  nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PANOTIFICATION_API_CHILDREN_CHANGED object:dict];
}

+(NSAttributedString*)attributedString:(NSString*)str
{
    return [PAApi attributedString:str color:nil bold:NO];
}

#define ATTRIBUTED_FONTSIZE 12

+(NSAttributedString*)attributedString:(NSString*)str color:(NSColor*)color bold:(BOOL)bold
{
    NSMutableAttributedString *mas = [[[NSMutableAttributedString alloc] initWithString:str] autorelease];
    NSFont *font = nil;
    
    if (bold) {
        font = [NSFont boldSystemFontOfSize:ATTRIBUTED_FONTSIZE];
    }
    else
    {
        font = [NSFont systemFontOfSize:ATTRIBUTED_FONTSIZE];
    }
    
    NSRange r = NSMakeRange(0, str.length);
    
    [mas beginEditing];
    [mas addAttribute:NSFontAttributeName
                value:font
                range:r];
    
    if (color)
    {
        [mas addAttribute:NSForegroundColorAttributeName
                    value:color
                    range:r];
    }
    [mas endEditing];
    return mas;
}

+(NSAttributedString*)attributedString:(NSString*)str color:(NSColor*)color fontSize:(CGFloat)fontSize bold:(BOOL)bold
{
    NSMutableAttributedString *mas = [[[NSMutableAttributedString alloc] initWithString:str] autorelease];
    NSFont *font = nil;
    
    if (bold) {
        font = [NSFont boldSystemFontOfSize:fontSize];
    }
    else
    {
        font = [NSFont systemFontOfSize:fontSize];
    }
    
    NSRange r = NSMakeRange(0, str.length);
    
    [mas beginEditing];
    [mas addAttribute:NSFontAttributeName
                value:font
                range:r];
    
    if (color)
    {
        [mas addAttribute:NSForegroundColorAttributeName
                    value:color
                    range:r];
    }
    [mas endEditing];
    return mas;
}

+(NSAttributedString*)attributedLogTime
{
    //把this的字体颜色变为红色
//    [attriString addAttribute:(NSString *)kCTForegroundColorAttributeName
//                        value:(id)[UIColor redColor].CGColor
//                        range:NSMakeRange(0, 4)];
//    //把is变为黄色
//    [attriString addAttribute:(NSString *)kCTForegroundColorAttributeName
//                        value:(id)[UIColor yellowColor].CGColor
//                        range:NSMakeRange(5, 2)];
//    //改变this的字体，value必须是一个CTFontRef
//    [attriString addAttribute:(NSString *)kCTFontAttributeName
//                        value:(id)CTFontCreateWithName((CFStringRef)[UIFont boldSystemFontOfSize:14].fontName,
//                                                       14,
//                                                       NULL)
//                        range:NSMakeRange(0, 4)];
//    //给this加上下划线，value可以在指定的枚举中选择
//    [attriString addAttribute:(NSString *)kCTUnderlineStyleAttributeName
//                        value:(id)[NSNumber numberWithInt:kCTUnderlineStyleDouble]
//                        range:NSMakeRange(0, 4)];
    
    NSTimeInterval ti = [[NSDate date] timeIntervalSince1970];
    NSString *ft = [DTUtil timeIntervalSince1970:ti Format:@"[yyyy-MM-dd HH:mm:ss]:"];
    
    return [PAApi attributedString:ft];
}
@end
