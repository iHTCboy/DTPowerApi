//
//  AutoSelectTextField.m
//  DTPowerApi
//
//  Created by leks on 13-1-5.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "ProjectTextField.h"
#import "PAObject.h"
#import "PAApi.h"
#import "PABean.h"
#import "PAProject.h"

@implementation ProjectTextField
@synthesize item;
@synthesize propertyKey;
@synthesize pDelegate;

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [propertyKey release];
    [item release];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(valueExistsNotification:) name:PANOTIFICATION_OBJECT_VALUE_EXISTS object:nil];
}

- (BOOL)textShouldEndEditing:(NSText *)textObject
{
    if (self.stringValue.length == 0) {
        return NO;
    }

    return YES;
}

-(void)reloadItem:(PAObject*)nitem
{
    self.item = nitem;
}

- (void)textDidEndEditing:(NSNotification *)notification
{
    [super textDidEndEditing:notification];
    [item setValue:self.stringValue forKey:propertyKey];
    
    if ([pDelegate respondsToSelector:@selector(textFieldDidChanged:)])
    {
        [pDelegate textFieldDidChanged:self];
    }
}

-(void)valueExistsNotification:(NSNotification*)notification
{
    NSDictionary *dict = notification.object;
    NSString *object_type = [dict objectForKey:@"object_type"];
    NSString *key = [dict objectForKey:@"key"];
    NSString *value = [dict objectForKey:@"value"];
    NSString *msg = [dict objectForKey:@"msg"];
    
    id object = [dict objectForKey:@"object"];
    
    if (object != self.item) {
        return;
    }
    
    NSAlert *alert = [NSAlert alertWithMessageText:msg defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [alert runModal];
    
    if ([object_type isEqualToString:[PABean className]])
    {
        if ([key isEqualToString:@"beanName"])
        {
            self.stringValue = value;
        }
        else if ([key isEqualToString:@"name"])
        {
            self.stringValue = value;
        }
    }
    else if ([object_type isEqualToString:[PAApi className]])
    {
        if ([key isEqualToString:@"name"])
        {
            self.stringValue = value;
        }
    }
    else if ([object_type isEqualToString:[PAProject className]])
    {
        if ([key isEqualToString:@"name"])
        {
            self.stringValue = value;
        }
    }
    [self setNeedsDisplay];
}
@end
