//
//  BasicInfoView.h
//  DTPowerApi
//
//  Created by leks on 13-1-14.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAObject.h"
#import "PAValidationTextField.h"

@interface BasicInfoView : NSView
{
    IBOutlet NSTextField *typeName;
    IBOutlet PAValidationTextField *name;
    IBOutlet NSTextField *desc;
    IBOutlet NSTextView *remark;
    
    PAObject *object;
}
@property (nonatomic, retain) PAObject *object;
-(void)reloadObject:(PAObject*)obj;
@end
