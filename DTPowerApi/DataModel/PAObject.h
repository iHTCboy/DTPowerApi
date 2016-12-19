//
//  PAObject.h
//  PowerApi
//
//  Created by leks on 12-7-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PAConstants.h"

@interface PAObject : NSObject<NSCopying>
{
    NSString *oid;              
    NSString *name;             
    NSString *desc;             
    NSString *comment;
    NSString *type;             
    NSString *typeName;         
    
    NSInteger rowIndex;
    BOOL expanded;
}
//id
@property (nonatomic, copy) NSString *oid;

//name
@property (nonatomic, copy) NSString *name;

//description, system define
@property (nonatomic, copy) NSString *desc;

//comment, user define
@property (nonatomic, copy) NSString *comment;

//object type:represents the PAOBJECT_SOURCE_TYPE
@property (nonatomic, copy) NSString *type;

//custom name for type, system define
@property (nonatomic, copy) NSString *typeName;

//tmp index for OutlineView, used in undo
@property (nonatomic) NSInteger rowIndex;

@property (nonatomic) BOOL expanded;
-(NSDictionary*)toDict;
-(NSString*)dictString;
-(id)initWithDict:(NSDictionary*)dict;

///////////////////////
+(NSString*)object:(NSObject*)object valueByValue:(NSString*)value forKey:(NSString*)key existsObjects:(NSArray*)earray;
+(BOOL)object:(NSObject*)object ValueExists:(NSString*)value forKey:(NSString*)key existsObjects:(NSArray*)earray;

+(NSIndexSet*)indexesForObjects:(NSArray*)objects inArray:(NSArray*)array;
@end
