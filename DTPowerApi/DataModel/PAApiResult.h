//
//  PAApiResult.h
//  DTPowerApi
//
//  Created by leks on 13-2-27.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAObject.h"

@class PAApi;

@interface PAApiResult : PAObject
{
    NSString *dateline;
    NSString *dateString;
    
    NSString *processTime;
    NSString *processString;
    
//    NSString *responseSrcString;
    NSString *responseJsonString;
    
    NSString *responseHeaderString;
    
    NSMutableArray *expandedItems;
    NSString *lastResultYOffset;
    
    BOOL isLocal;
    
    PAApi *parentApi;
    NSString *groupName;
    
    NSString *sentSize;
    NSString *receivedSize;
    
    NSString *responseStatus;
    NSString *responseHeaders;
    NSString *responseString;
}
@property (nonatomic, copy) NSString *dateline;
@property (nonatomic, copy) NSString *dateString;

@property (nonatomic, copy) NSString *processTime;
@property (nonatomic, copy) NSString *processString;

//@property (nonatomic, copy) NSString *responseSrcString;
@property (nonatomic, copy) NSString *responseJsonString;
@property (nonatomic, copy) NSString *responseHeaderString;

@property (nonatomic, retain) NSMutableArray *expandedItems;
@property (nonatomic, copy) NSString *lastResultYOffset;

@property (nonatomic, assign) PAApi *parentApi;
@property (nonatomic, retain) NSString *groupName;

@property (nonatomic, copy) NSString *sentSize;
@property (nonatomic, copy) NSString *receivedSize;

@property (nonatomic, copy) NSString *responseStatus;
@property (nonatomic, copy) NSString *responseHeaders;
@property (nonatomic, copy) NSString *responseString;
@property (nonatomic) BOOL isLocal;

-(void)start;
-(void)stop;

-(void)resetAsLocal;
@end
