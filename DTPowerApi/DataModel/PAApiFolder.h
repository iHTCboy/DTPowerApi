//
//  PAApiFolder.h
//  DTPowerApi
//
//  Created by leks on 13-1-4.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAObject.h"
@class PAApi;
@class PAProject;

@interface PAApiFolder : PAObject
{
    NSMutableArray *allChildren;
    NSMutableArray *children;
    PAProject *project;
    NSString *filterKeyword;
}
@property (nonatomic, retain) NSMutableArray *allChildren;
@property (nonatomic, retain) NSMutableArray *children;
@property (nonatomic, assign) PAProject *project;
@property (nonatomic, retain) NSString *filterKeyword;

-(PAApi*)defaultApi;
-(void)filterChildren:(NSString*)keyword;
-(void)refilterChildren;
-(void)refreshApiIndexes;

@end
