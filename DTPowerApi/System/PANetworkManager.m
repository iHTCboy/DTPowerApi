//
//  DTPNetworkManager.m
//  DTPowerApi
//
//  Created by leks on 12-12-27.
//  Copyright (c) 2012年 leks. All rights reserved.
//

#import "PANetworkManager.h"
#define TIME_OUT_SECOND_GET 20
#define TIME_OUT_SECOND_POST 30
#import "PAParam.h"
#import "PAApi.h"
#import "PAParamGroup.h"
#import "PAProject.h"

@implementation PANetworkManager

-(BOOL)filter:(NetworkHeader*)header
{
    BOOL ret = YES;
	if (header.reqType == HEADER_REQ_DOWNIMG || header.reqType == HEADER_REQ_DOWNRESIZEIMG)
	{
		return YES;
	}
//    header.request.contentLength;
    NSString *responseString = (NSString*)header.data;
    NSLog(@"%@:%@", header.reqName, responseString);
    
	return ret;
}

-(NetworkHeader*)startRequestForApi:(PAApi*)api Delg:(id<NetworkProtocol>)delg
{
    NSString *urlStr =api.requestUrlString;
    NSLog(@"%@", urlStr);
    
    [self registNetwork:delg];
    ASIHTTPRequest *req = nil;
    
    //get
    if (api.selectedParamGroup.postDatas.count == 0)
    {
        req = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:api.requestUrlString]];
    }
    else
    {
        //post
        ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:api.requestUrlString]];
        
        for (PAParam *p in api.selectedParamGroup.postDatas)
        {
            if ([p.paramType isEqualToString:PAPARAM_TYPE_FILE])
            {
                [request addFile:p.filename forKey:p.paramKey];
            }
            else
            {
                [request addPostValue:p.paramValue forKey:p.paramKey];
            }
        }
        
        for (int i=0; i<api.project.commonPostDatas.count; i++)
        {
            PAParam *pp = [api.project.commonPostDatas objectAtIndex:i];
            BOOL exists = NO;
            for (int j=0; j<api.selectedParamGroup.postDatas.count; j++)
            {
                PAParam *p = [api.selectedParamGroup.postDatas objectAtIndex:j];
                if ([p.paramKey isEqualToString:pp.paramKey])
                {
                    exists = YES;
                }
            }
            
            if (exists) {
                continue ;
            }
            
            if ([pp.paramType isEqualToString:PAPARAM_TYPE_FILE])
            {
                [request addFile:pp.filename forKey:pp.paramKey];
            }
            else
            {
                [request addPostValue:pp.paramValue forKey:pp.paramKey];
            }
        }
        req = request;
    }
    
    [req setDelegate:self];
    req.timeOutSeconds = TIME_OUT_SECOND_POST;
    
    NetworkHeader *header = [[NetworkHeader alloc] init];
    header.netDelegate = delg;
    header.request = req;
    header.requestData = api;
    header.reqType = 100;
    
    [networkQueue addOperation:req];
    NSString *key = [NSString stringWithFormat:@"%p", req];
    [queueMapping setObject:header forKey:key];
    [networkQueue go];
    [header release];
    [req release];
    return header;
}
@end
