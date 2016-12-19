//
//  PAValidationTextField.m
//  DTPowerApi
//
//  Created by leks on 13-2-22.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAValidationTextField.h"

@implementation PAValidationTextField
@synthesize item;
@synthesize propertyKey;

-(void)dealloc
{
    [item release];
    [propertyKey release];
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

- (BOOL)textShouldEndEditing:(NSText *)textObject
{
    if (self.stringValue.length == 0)
    {
        NSString *msg = nil;
        if ([self.propertyKey isEqualToString:@"name"])
        {
            msg = @"Name can not be empty!";
        }
        else if ([self.propertyKey isEqualToString:@"beanName"])
        {
            msg = @"Class name can not be empty!";
        }
        
        NSAlert *alert = [NSAlert alertWithMessageText:msg defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
        [alert runModal];
        NSString *nv = [self.item valueForKey:self.propertyKey];
        if (nv) {
            self.stringValue = nv;
        }
//        self.stringValue = [item valueForKey:self.propertyKey];
        return NO;
    }
    
    return [super textShouldEndEditing:textObject];
}

//- (void)textDidEndEditing:(NSNotification *)notification
//{
//    [super textDidEndEditing:notification];
//}
@end
