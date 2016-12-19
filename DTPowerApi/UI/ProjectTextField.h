//
//  AutoSelectTextField.h
//  DTPowerApi
//
//  Created by leks on 13-1-5.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAObject.h"

@class ProjectTextField;

@protocol ProjectTextFieldDelegate <NSObject>

-(void)textFieldDidChanged:(ProjectTextField*)textField;

@end

@interface ProjectTextField : NSTextField
{
    PAObject *item;
    NSString *propertyKey;
    
    id<ProjectTextFieldDelegate> pDelegate;
}
@property (nonatomic, retain) PAObject *item;
@property (nonatomic, copy) NSString *propertyKey;
@property (nonatomic, assign) IBOutlet id<ProjectTextFieldDelegate> pDelegate;

-(void)reloadItem:(PAObject*)nitem;
@end
