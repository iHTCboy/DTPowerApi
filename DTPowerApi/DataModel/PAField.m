//
//  PAField.m
//  DTPowerApi
//
//  Created by leks on 13-1-24.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAField.h"
#import "DTUtil.h"
#import "JSON.h"

@implementation PAField
@synthesize fieldName;
@synthesize fieldType;

@synthesize fieldValue;
@synthesize parentMappingKey;
@synthesize mappingKey;

@synthesize subFields;
@synthesize parentField;
@synthesize linkStatus;
@synthesize fromProperty;
@synthesize beanName;

-(void)dealloc
{
    [fieldName release];
    [fieldType release];
    [fieldValue release];
    [parentMappingKey release];
    [mappingKey release];
    [subFields release];
    [beanName release];
    [parentField release];
    [super dealloc];
}

-(id)init
{
    if (self = [super init])
    {
        self.fieldName = @"";
        self.fieldType = @"";
        self.fieldValue = @"";
        self.mappingKey = @"";
        self.parentMappingKey = @"";
        self.beanName = @"";
        self.subFields = [NSMutableArray arrayWithCapacity:10];
        self.linkStatus = kPAFieldLinkStatusUndefined;
    }
    
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    PAField *field = [super copyWithZone:zone];
    if (field) {
        field.beanName = self.beanName;
        field.fieldName = self.fieldName;
        field.fieldType = self.fieldType;
        field.fieldValue = self.fieldValue;
        field.parentMappingKey = self.parentMappingKey;
        field.mappingKey = self.mappingKey;
        field.subFields = [[[NSMutableArray alloc] initWithArray:self.subFields copyItems:YES] autorelease];
    }

    return field;
}

-(id)basicCopy
{
    PAField *field = [[PAField alloc] init];
    field.beanName = self.beanName;
    field.fieldName = self.fieldName;
    field.fieldType = self.fieldType;
    field.fieldValue = self.fieldValue;
    field.parentMappingKey = self.parentMappingKey;
    field.mappingKey = self.mappingKey;
    
    return [field autorelease];
}

+(id)emptyField
{
    PAField *field = [[PAField alloc] init];
    field.fieldName = PAFIELD_TYPE_EMPTY;
    field.fieldType = PAFIELD_TYPE_EMPTY;
    return [field autorelease];
}

-(id)initWithDict:(NSDictionary *)dict
{
    if (self = [super initWithDict:dict])
    {
        DICT_ASSIGN1(fieldName);
        DICT_ASSIGN1(fieldType);
        DICT_ASSIGN1(fieldValue);
        DICT_ASSIGN1(parentMappingKey);
        DICT_ASSIGN1(mappingKey);
        DICT_ASSIGN1(beanName);
        
        self.subFields = [NSMutableArray arrayWithCapacity:10];
        NSArray *tmp = [dict objectForKey:@"subFields"];
        for (int i=0; i<tmp.count; i++)
        {
            NSDictionary *d = [tmp objectAtIndex:i];
            PAField *sField = [[PAField alloc] initWithDict:d];
            [self.subFields addObject:sField];
            [sField release];
        }
    }
    return self;
}

-(NSDictionary*)toDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
    [md setDictionary:[super toDict]];
    DICT_EXPORT1(fieldName);
    DICT_EXPORT1(fieldType);
    DICT_EXPORT1(fieldValue);
    DICT_EXPORT1(parentMappingKey);
    DICT_EXPORT1(mappingKey);
    DICT_EXPORT1(beanName);
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
    for (int i=0; i<subFields.count; i++)
    {
        PAField *field = [subFields objectAtIndex:i];
        [ma addObject:[field toDict]];
    }
    
    [md setObject:ma forKey:@"subFields"];
    return md;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"%@", [self toDict]];
    
    return [[self toDict] JSONRepresentation];
    
    return [NSString stringWithFormat:@"fieldName:%@, fieldType:%@, fieldValue:%@, parentKey:%@, mappingKey:%@, subFields:%@", fieldName, fieldType, fieldValue, parentMappingKey, mappingKey, subFields];
}

- (NSComparisonResult)caseInsensitiveCompare:(PAField *)field
{
    return [[self.fieldName lowercaseString] caseInsensitiveCompare:[field.fieldName lowercaseString]];
}
@end
