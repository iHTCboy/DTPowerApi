//
//  PAField.h
//  DTPowerApi
//
//  Created by leks on 13-1-24.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAObject.h"

#define PAFIELD_TYPE_NULL @"Null"
#define PAFIELD_TYPE_UNDEFINED @"Undefined"
#define PAFIELD_TYPE_OBJECT @"Object"
#define PAFIELD_TYPE_ARRAY @"Array"
#define PAFIELD_TYPE_STRING @"String"
#define PAFIELD_TYPE_NUMBER @"Number"
#define PAFIELD_TYPE_EMPTY @"Empty"

#define PAFIELD_NAME_COLOR_COMMON [NSColor colorWithCalibratedRed:100.0/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0]
#define PAFIELD_NAME_COLOR_PROPERTY [NSColor colorWithCalibratedRed:122/255.0 green:49/255.0 blue:0.0/255.0 alpha:1.0]
// [NSColor colorWithCalibratedRed:33.0/255.0 green:33.0/255.0 blue:33.0/255.0 alpha:1.0]
#define PAFIELD_COLOR_COMMON [NSColor colorWithCalibratedRed:33.0/255.0 green:33.0/255.0 blue:33.0/255.0 alpha:1.0]

#define PAFIELD_COLOR_NULL [NSColor redColor]
#define PAFIELD_COLOR_UNDEFINED [NSColor colorWithCalibratedRed:188.0/255.0 green:188.0/255.0 blue:188.0/255.0 alpha:1.0]
#define PAFIELD_COLOR_EMPTY [NSColor colorWithCalibratedRed:188.0/255.0 green:188.0/255.0 blue:188.0/255.0 alpha:1.0]
#define PAFIELD_COLOR_STRING [NSColor greenColor]
#define PAFIELD_COLOR_NUMBER [NSColor blueColor]
#define PAFIELD_COLOR_OBJECT [NSColor blackColor]
#define PAFIELD_COLOR_ARRAY [NSColor purpleColor]

#define PAFIELD_STATUS_COLOR_UNDEFINED [NSColor colorWithCalibratedRed:188.0/255.0 green:188.0/255.0 blue:188.0/255.0 alpha:1.0]
#define PAFIELD_STATUS_COLOR_NOTLINK [NSColor lightGrayColor]
#define PAFIELD_STATUS_COLOR_OK [NSColor greenColor]
#define PAFIELD_STATUS_COLOR_FAIL [NSColor redColor]

#define PAFIELD_TYPE_COLORS [NSDictionary dictionaryWithObjectsAndKeys:PAFIELD_COLOR_NULL, PAFIELD_TYPE_NULL,\
PAFIELD_COLOR_EMPTY, PAFIELD_TYPE_EMPTY,\
PAFIELD_COLOR_STRING, PAFIELD_TYPE_STRING,\
PAFIELD_COLOR_NUMBER, PAFIELD_TYPE_NUMBER,\
PAFIELD_COLOR_OBJECT, PAFIELD_TYPE_OBJECT,\
PAFIELD_COLOR_ARRAY, PAFIELD_TYPE_ARRAY,\
PAFIELD_COLOR_UNDEFINED, PAFIELD_TYPE_UNDEFINED,nil]

#define PAFIELD_STATUS_COLORS [NSArray arrayWithObjects:PAFIELD_STATUS_COLOR_UNDEFINED, PAFIELD_STATUS_COLOR_NOTLINK, PAFIELD_STATUS_COLOR_OK, PAFIELD_STATUS_COLOR_FAIL,nil]

#define PAFIELD_FONT_COMMON [NSFont systemFontOfSize:12.0f]
#define PAFIELD_FONT_BOLD [NSFont boldSystemFontOfSize:12.0f]
enum _PAFIELD_LINK_STATUS {
    kPAFieldLinkStatusUndefined = 0,
    kPAFieldLinkStatusNotLink,
    kPAFieldLinkStatusOK,
    kPAFieldLinkStatusFail
};

@interface PAField : PAObject
{
    NSString *fieldName;
    NSString *fieldType;
    
    NSString *fieldValue;
    NSString *parentMappingKey;
    NSString *mappingKey;
    
    NSMutableArray *subFields;
    
    PAField *parentField;
    
    NSInteger linkStatus;
    
    BOOL fromProperty;
    NSString *beanName;
}
@property (nonatomic, copy) NSString *fieldName;
@property (nonatomic, copy) NSString *fieldType;

@property (nonatomic, copy) NSString *fieldValue;
@property (nonatomic, copy) NSString *parentMappingKey;
@property (nonatomic, copy) NSString *mappingKey;

@property (nonatomic, retain) NSMutableArray *subFields;
@property (nonatomic, retain) PAField *parentField;

//one of link success, not link, link failed
@property (nonatomic) NSInteger linkStatus;

@property (nonatomic) BOOL fromProperty;
@property (nonatomic, retain) NSString *beanName;
-(id)basicCopy;
+(id)emptyField;
- (NSComparisonResult)caseInsensitiveCompare:(PAField *)field;
@end
