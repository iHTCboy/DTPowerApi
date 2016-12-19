//
//  PAMapping.h
//  DTPowerApi
//
//  Created by leks on 13-1-25.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAObject.h"

@interface PAMapping : PAObject
{
    NSMutableDictionary *beanMapping;
}
@property (nonatomic, retain) NSMutableDictionary *beanMapping;
@end
