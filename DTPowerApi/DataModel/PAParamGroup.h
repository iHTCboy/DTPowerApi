//
//  PAParamGroup.h
//  DTPowerApi
//
//  Created by leks on 13-2-27.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAObject.h"

@class PAApi;
@class PAParam;

@interface PAParamGroup : PAObject
{
    PAApi *parentApi;
    NSMutableArray *getParams;
    NSMutableArray *postDatas;
}
@property (nonatomic, retain) NSMutableArray *getParams;
@property (nonatomic, retain) NSMutableArray *postDatas;
@property (nonatomic, assign) PAApi *parentApi;

-(PAApi*)parentApi;
-(void)setParentApi:(PAApi *)pa;

-(PAParam*)defaultGetParam;
-(PAParam*)defaultPostParam;

-(NSString*)newParamValueByValue:(NSString*)value forKey:(NSString*)key isPost:(BOOL)isPost;
-(BOOL)paramValueExists:(NSString*)value forKey:(NSString*)key isPost:(BOOL)isPost;

-(void)insertParams:(NSArray *)array isPost:(BOOL)isPost;
-(void)removeParams:(NSArray *)array isPost:(BOOL)isPost;
@end
