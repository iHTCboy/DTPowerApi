//
//  BasicInfoView.m
//  DTPowerApi
//
//  Created by leks on 13-1-14.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "BasicInfoView.h"
#import "ProjectTextField.h"
#import "PAApi.h"
#import "PABean.h"
#import "PAProject.h"

@implementation BasicInfoView
@synthesize object;

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [object release];
    [super dealloc];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.

    }
    
    return self;
}

-(void)awakeFromNib
{
    name.propertyKey = @"name";
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectSelectionChanged:) name:PANOTIFICATION_PROJECTPANEL_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(valueExistsNotification:) name:PANOTIFICATION_OBJECT_VALUE_EXISTS object:nil];
    
//    CALayer *viewLayer = [CALayer layer];
//    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0)]; //RGB plus Alpha Channel
////    [self setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
//    [self setLayer:viewLayer];
    remark.font = [NSFont systemFontOfSize:12.0];
}

-(void)objectSelectionChanged:(NSNotification*)notification
{
    self.object = notification.object;
    name.item = self.object;
}

-(void)valueExistsNotification:(NSNotification*)notification
{
    NSDictionary *dict = notification.object;
    NSString *object_type = [dict objectForKey:@"object_type"];
    NSString *key = [dict objectForKey:@"key"];
    NSString *value = [dict objectForKey:@"value"];
    id obj = [dict objectForKey:@"object"];
    
    if (obj != self.object) {
        return;
    }
    
    if ([object_type isEqualToString:[PABean className]])
    {
        if ([key isEqualToString:@"beanName"])
        {
            name.stringValue = value;
        }
        else if ([key isEqualToString:@"name"])
        {
            name.stringValue = value;
        }
    }
    else if ([object_type isEqualToString:[PAApi className]])
    {
        if ([key isEqualToString:@"name"])
        {
            name.stringValue = value;
        }
    }
    else if ([object_type isEqualToString:[PAProject className]])
    {
        if ([key isEqualToString:@"name"])
        {
            name.stringValue = value;
        }
    }
}

-(void)reloadObject:(PAObject*)obj
{
    self.object = obj;
    name.item = obj;
}
@end
