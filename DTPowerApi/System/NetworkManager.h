//
//  NetworkManager.h
//  MiniBlog
//
//  Created by jsb on 11-3-18.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "ASIFormDataRequest.h"

enum NETWORK_HEADER_REPLY_TYPE 
{
	HEADER_REPLY_SUCCESS,
	HEADER_REPLY_CONN_ERROR,
	HEADER_REPLY_REQ_TIMEOUT
};

enum _NETWORK_HEADER_REQ_TYPE 
{
    HEADER_REQ_DOWNIMG,
	HEADER_REQ_DOWNRESIZEIMG
};

@class NetworkHeader;
//@class DTImageOption;

@protocol NetworkProtocol
-(void)networkFinished:(NetworkHeader*)header;
-(void)networkFailed:(NetworkHeader*)header;
@end

//	自定义网络数据包头，用于区分不同类型的请求和回复
@interface NetworkHeader : NSObject
{
	NSUInteger replyType;			//回复值
	NSUInteger reqType;				//请求类型
    NSString *reqName;             //请求方法名
	id data;					//返回数据
    id requestData;
	id <NetworkProtocol> netDelegate; //
	ASIHTTPRequest *request;
}
@property (nonatomic) NSUInteger replyType;
@property (nonatomic) NSUInteger reqType;
@property (nonatomic, retain) NSString *reqName; 
@property (nonatomic, retain) id data;
@property (nonatomic, retain) id requestData;
@property (nonatomic, assign) id <NetworkProtocol> netDelegate;
@property (nonatomic, retain) ASIHTTPRequest *request;
@end



//网络管理器
@interface NetworkManager : NSObject 
{
	//httprequest队列
	ASINetworkQueue *networkQueue;
	NSMutableDictionary *queueMapping;
    NSMutableDictionary *registedInstances;
    BOOL threadLock;
	NSString *downloadImageFolder;
    
}
@property (nonatomic, retain) NSString *downloadImageFolder;

-(NetworkHeader*)downloadImage:(NSString*)imgUrl LocaleFile:(NSString*)filename Delegate:(id)delg;
-(NetworkHeader*)downloadAndResizeImage:(NSString*)imgUrl LocaleFile:(NSString*)filename Delegate:(id)delg;
//-(NetworkHeader*)downloadImage:(DTImageOption*)imgOption Delegate:(id)delg;

-(NetworkHeader*)addGetOperation:(NSString*)urlStr ReqType:(NSUInteger)reqType Delegate:(id)delg;
-(NetworkHeader*)addPostOperation:(NSString*)urlStr ReqType:(NSUInteger)reqType PostDatas:(NSDictionary*)postDatas Delegate:(id)delg;
-(BOOL)checkRegist:(id)instanceAddress;
//处理返回值转换
-(BOOL)filter:(NetworkHeader*)header;
//增加网络控制防止崩溃
-(BOOL)registNetwork:(id)instanceAddress;
-(BOOL)unregistNetwork:(id)instanceAddress;

-(void)cancelHeader:(NetworkHeader*)header;
@end




