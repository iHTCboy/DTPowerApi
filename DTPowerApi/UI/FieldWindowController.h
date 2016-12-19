//
//  FieldWindowController.h
//  DTPowerApi
//
//  Created by leks on 13-5-31.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAField.h"

@interface FieldWindowController : NSWindowController
{
    PAField *field;
    IBOutlet NSTextView *valueView;
}
@property (nonatomic, retain) PAField *field;
@end
