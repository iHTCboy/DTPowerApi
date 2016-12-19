//
//  FieldWindowController.m
//  DTPowerApi
//
//  Created by leks on 13-5-31.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "FieldWindowController.h"

@implementation FieldWindowController
@synthesize field;

-(void)dealloc
{
    [field release];
    [super dealloc];
}

-(void)windowDidLoad
{
    [valueView setFont:[NSFont systemFontOfSize:13.0f]];
    [valueView setEditable:NO];
}

- (BOOL)windowShouldClose:(id)sender
{
    
    [[NSApplication sharedApplication] stopModal];
    return YES;
}
@end
