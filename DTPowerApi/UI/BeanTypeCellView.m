//
//  BeanTypeCellView.m
//  DTPowerApi
//
//  Created by leks on 13-1-29.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "BeanTypeCellView.h"
#import "PAField.h"

@implementation BeanTypeCellView
@synthesize popupBtn;
@synthesize field;
@synthesize btDelegate;
@synthesize lastType;

-(void)dealloc
{
    [popupBtn release];
    [field release];
    [lastType release];
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

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

-(IBAction)selctionChangedAction:(id)sender
{
    NSString *newType = self.popupBtn.selectedItem.title;
    NSString *currentType = self.textField.stringValue;
    self.lastType = currentType;
    
    if (![newType isEqualToString:currentType])
    {
        if ([btDelegate respondsToSelector:@selector(beanType:DidChangedTo:forField:)])
        {
            [btDelegate beanType:self DidChangedTo:newType forField:field];
        }
    }
}

@end
