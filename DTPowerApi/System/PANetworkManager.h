//
//  DTPNetworkManager.h
//  DTPowerApi
//
//  Created by leks on 12-12-27.
//  Copyright (c) 2012年 leks. All rights reserved.
//

#import "NetworkManager.h"

@class PAApi;

@interface PANetworkManager : NetworkManager
{
    
}

-(NetworkHeader*)startRequestForApi:(PAApi*)api Delg:(id<NetworkProtocol>)delg;
@end
