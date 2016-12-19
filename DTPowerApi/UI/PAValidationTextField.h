//
//  PAValidationTextField.h
//  DTPowerApi
//
//  Created by leks on 13-2-22.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAObject.h"

@interface PAValidationTextField : NSTextField
{
    id item;
    NSString *propertyKey;
}
@property (nonatomic, retain) id item;
@property (nonatomic, retain) NSString *propertyKey;
@end
