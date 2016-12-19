//
//  NetworkManager.m
//  MiniBlog
//
//  Created by jsb on 11-3-18.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "NetworkManager.h"
//#import "DTImageOption.h"

//#import "JSON.h"
#define TIME_OUT_SECOND_GET 20
#define TIME_OUT_SECOND_POST 30

@implementation NetworkHeader
@synthesize replyType;
@synthesize reqType;
@synthesize data;
@synthesize requestData;
@synthesize netDelegate;
@synthesize request;
@synthesize reqName;

-(void)dealloc
{
    [reqName release];
    [data release];
    [requestData release];
    [request release];
    [super dealloc];
}
@end


@implementation NetworkManager
@synthesize downloadImageFolder;

-(id)init
{
	if (self = [super init]) 
	{
		networkQueue = [[ASINetworkQueue alloc] init];
		[networkQueue setDelegate:self];
        [networkQueue setShouldCancelAllRequestsOnFailure:NO];
		queueMapping = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
        registedInstances = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
        threadLock = NO;
	}
	return self;
}

-(void)dealloc
{
	
	[queueMapping removeAllObjects];
	[queueMapping release];
	
	[networkQueue cancelAllOperations];
	[networkQueue release];
	[registedInstances release];
	[downloadImageFolder release];
	[super dealloc];
}

-(BOOL)registNetwork:(id)instanceAddress
{
    if (!instanceAddress) {
        return NO;
    }
    NSString *key = [NSString stringWithFormat:@"%p", instanceAddress];
    NSString *value = [NSString stringWithFormat:@"%p", instanceAddress];
    @synchronized(registedInstances)
    {
        [registedInstances setObject:value forKey:key];
    }
    
    return YES;
}

-(BOOL)unregistNetwork:(id)instanceAddress
{
    if (!instanceAddress) {
        return NO;
    }
    NSString *key = [NSString stringWithFormat:@"%p", instanceAddress];
    @synchronized(registedInstances)
    {
        [registedInstances removeObjectForKey:key];
    }
    
    @synchronized(queueMapping)
    {
        NSArray *headerKeys = [queueMapping allKeys];
        for (int i=0; i<[headerKeys count]; i++) 
        {
            NetworkHeader *header = [queueMapping objectForKey:[headerKeys objectAtIndex:i]];
            NSString *k = [NSString stringWithFormat:@"%p", header.netDelegate];
            if ([key isEqualToString:k]) 
            {
                NSLog(@"unregist %@", k);
                [header.request clearDelegatesAndCancel];
                header.request = nil;
            }
        }
    }
    
    //    threadLock = NO;
    return YES;
}

-(BOOL)checkRegist:(id)instanceAddress
{
    if (!instanceAddress) {
        return NO;
    }
    
    NSString *key = [NSString stringWithFormat:@"%p", instanceAddress];
    NSObject *obj = nil;
    @synchronized(registedInstances)
    {
        obj = [registedInstances objectForKey:key];
    }
    
    if (obj) 
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

-(NetworkHeader*)addGetOperation:(NSString*)urlStr ReqType:(NSUInteger)reqType Delegate:(id)delg
{
    if (![self registNetwork:delg]) 
    {
        //        return nil;
    }
    
    NSLog(@"murl:{%@}", urlStr);
	ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:urlStr]];
	[request setDelegate:self];
	request.timeOutSeconds = TIME_OUT_SECOND_GET;
    
    NetworkHeader *header = [[NetworkHeader alloc] init];
	header.netDelegate = delg;
	header.request = request;
	header.reqType = reqType;
	
	[networkQueue addOperation:request];
	NSString *key = [NSString stringWithFormat:@"%p", request];
	[queueMapping setObject:header forKey:key];
	[networkQueue go];
	[header release];
    [request release];
    
    return header;
}

-(NetworkHeader*)addPostOperation:(NSString*)urlStr ReqType:(NSUInteger)reqType PostDatas:(NSDictionary*)postDatas Delegate:(id)delg
{
    if (![self registNetwork:delg]) 
    {
        //        return nil;
    }
    //NSString* murl = [NSString stringWithFormat:@"%@%@",G_BASE_URL,[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	//NSLog(@"murl:{%@}", murl);
	ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:urlStr]];
	[request setDelegate:self];
    request.timeOutSeconds = TIME_OUT_SECOND_POST;
    for (NSString *key in [postDatas allKeys])
    {
        NSObject *value = [postDatas objectForKey:key];
        if ([value isKindOfClass:[NSData class]]) 
        {
            [request addData:value withFileName:@"pic.jpg" andContentType:@"file" forKey:key];
        }
        else
        {
            [request addPostValue:[postDatas objectForKey:key] forKey:key];
        }
    }
    
    NetworkHeader *header = [[NetworkHeader alloc] init];
	header.netDelegate = delg;
	header.request = request;
	header.reqType = reqType;
	
	[networkQueue addOperation:request];
	NSString *key = [NSString stringWithFormat:@"%p", request];
	[queueMapping setObject:header forKey:key];
	[networkQueue go];
	[header release];
    [request release];
	return header;
}

#pragma mark -
#pragma mark === 请求成功 ===
#pragma mark -
- (void)requestFinished:(ASIHTTPRequest *)request 
{
    @synchronized(queueMapping)
    {
        NSString *key = [NSString stringWithFormat:@"%p", request];
        NetworkHeader *header = [queueMapping objectForKey:key];
        if (header) 
        {
            if (header.reqType != HEADER_REQ_DOWNIMG && header.reqType != HEADER_REQ_DOWNRESIZEIMG) {
                header.data = [request responseString];
            }
            
            if ([self filter:header]) 
            {
                //线程锁
                if ([self checkRegist:header.netDelegate]) 
                {
                    [header.netDelegate networkFinished:header];
                }
            }
            else 
            {
                //线程锁
                if ([self checkRegist:header.netDelegate]) 
                {
                    [header.netDelegate networkFailed:header];
                }
            }
            
            //            header.request = nil;
            [queueMapping removeObjectForKey:key];
        }
    }
	
}

#pragma mark -
#pragma mark === 请求失败 ===
#pragma mark -
- (void)requestFailed:(ASIHTTPRequest *)request
{
    @synchronized(queueMapping)
    {
        NSString *key = [NSString stringWithFormat:@"%p", request];
        NetworkHeader *header = [queueMapping objectForKey:key];
        if (header) 
        {
            //header.data = [error localizedDescription];
            NSError *error = [request error];
            NSLog(@"%@", [error localizedDescription]);
            
            if (request.responseStatusMessage) {
                header.data = [NSString stringWithFormat:@"%d::%@", request.responseStatusCode, request.responseStatusMessage];
            }
            else
            {
                header.data = [error localizedDescription];
            }
            
            if (header.reqType != HEADER_REQ_DOWNIMG && header.reqType != HEADER_REQ_DOWNRESIZEIMG)
            {
                header.data = [request.error localizedDescription];
            }
            header.replyType = HEADER_REPLY_REQ_TIMEOUT;
            
            //            header.request = nil;
            //线程锁
            if ([self checkRegist:header.netDelegate]) 
            {
                [header.netDelegate networkFailed:header];
            }
            
            [queueMapping removeObjectForKey:key];
        }
        
        
    }
}


//处理返回值转换 子类继承
-(BOOL)filter:(NetworkHeader*)header
{
	return NO;
}

-(NetworkHeader*)downloadImage:(NSString*)imgUrl LocaleFile:(NSString*)filename Delegate:(id)delg
{
    if (![self registNetwork:delg]) 
    {
        NSLog(@"registed %@ failed...", delg);
        return nil;
    }
    //NSString *dpath = [g_LocaleFileManager getCachedImagePath];
    if (!filename || !imgUrl) 
    {
        return nil;
    }
    
    NSString *dpath = [NSString stringWithFormat:@"%@/%@", downloadImageFolder, filename];
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:imgUrl]];
    
	[request setDelegate:self];
	request.timeOutSeconds = 10;
    
    NetworkHeader *header = [[NetworkHeader alloc] init];
	header.netDelegate = delg;
	header.request = request;
	header.reqType = HEADER_REQ_DOWNIMG;
    header.data = filename;
    
	[request setDownloadDestinationPath:dpath];
    [request setAllowResumeForFileDownloads:YES];
    
	[networkQueue addOperation:request];
	NSString *key = [NSString stringWithFormat:@"%p", request];
	[queueMapping setObject:header forKey:key];
	[networkQueue go];
	[header release];
    [request release];
	return header;
}

-(NetworkHeader*)downloadAndResizeImage:(NSString*)imgUrl LocaleFile:(NSString*)filename Delegate:(id)delg
{
	if (![self registNetwork:delg]) 
    {
        NSLog(@"registed %@ failed...", delg);
        return nil;
    }
    //NSString *dpath = [g_LocaleFileManager getCachedImagePath];
    if (!filename || !imgUrl) 
    {
        return nil;
    }
    
    NSString *dpath = [NSString stringWithFormat:@"%@/%@", downloadImageFolder, filename];
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:imgUrl]];
	[request setDelegate:self];
    //防盗链
    //    [request addRequestHeader:@"Referer" value:@"http://bbs.hefei.cc/"];
	request.timeOutSeconds = 30;
    
    NetworkHeader *header = [[NetworkHeader alloc] init];
	header.netDelegate = delg;
	header.request = request;
	header.reqType = HEADER_REQ_DOWNRESIZEIMG;
    header.data = filename;
    
	[request setDownloadDestinationPath:dpath];
    [request setAllowResumeForFileDownloads:YES];
    
	[networkQueue addOperation:request];
	NSString *key = [NSString stringWithFormat:@"%p", request];
	[queueMapping setObject:header forKey:key];
	[networkQueue go];
	[header release];
    [request release];
	return header;
}

//-(NetworkHeader*)downloadImage:(DTImageOption*)imgOption Delegate:(id)delg
//{
//    if (![self registNetwork:delg])
//    {
//        NSLog(@"registed %@ failed...", delg);
//        return nil;
//    }
//    //NSString *dpath = [g_LocaleFileManager getCachedImagePath];
//    if (!imgOption)
//    {
//        return nil;
//    }
//    
//    NSString *dpath = [NSString stringWithFormat:@"%@/%@", downloadImageFolder, imgOption.key];
//    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:imgOption.url]];
//    
//	[request setDelegate:self];
//	request.timeOutSeconds = 10;
//    
//    NetworkHeader *header = [[NetworkHeader alloc] init];
//	header.netDelegate = delg;
//	header.request = request;
//	header.reqType = HEADER_REQ_DOWNIMG;
//    header.data = imgOption;
//    
//	[request setDownloadDestinationPath:dpath];
//    [request setAllowResumeForFileDownloads:YES];
//    
//	[networkQueue addOperation:request];
//	NSString *key = [NSString stringWithFormat:@"%p", request];
//	[queueMapping setObject:header forKey:key];
//	[networkQueue go];
//	[header release];
//    [request release];
//	return header;
//}

-(void)cancelHeader:(NetworkHeader*)header
{
    if (!header) {
        return ;
    }
    NSString *key = [NSString stringWithFormat:@"%p", header.request];
    header.netDelegate = nil;
    [header.request clearDelegatesAndCancel];
    [queueMapping removeObjectForKey:key];
}
@end
