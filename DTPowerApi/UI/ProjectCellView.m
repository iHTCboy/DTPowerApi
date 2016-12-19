//
//  ProjectCellView.m
//  DTPowerApi
//
//  Created by leks on 13-1-7.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "ProjectCellView.h"
#import "PAApiFolder.h"
#import "PABeanFolder.h"

@implementation ProjectCellView
@synthesize numberBg;
@synthesize numberLabel;
@synthesize status;
@synthesize normalImage;
@synthesize highlightedImage;
@synthesize normalStatusImage;
@synthesize highlightedStatusImage;
@synthesize normalBgImage;
@synthesize hightlightedBgImage;
@synthesize data;

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [numberBg release];
    [numberLabel release];
    [status release];
    [normalImage release];
    [highlightedImage release];
    
    [normalStatusImage release];
    [highlightedStatusImage release];
    
    [normalBgImage release];
    [hightlightedBgImage release];
    [data release];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectChildrenNumberChanged:) name:PANOTIFICATION_PROJECT_CHILDREN_NUMBER_CHANGED object:nil];
}

-(void)projectChildrenNumberChanged:(NSNotification*)notification
{
    if (notification.object == self.data)
    {
        if ([self.data isKindOfClass:[PAApiFolder class]]) {
            PAApiFolder *folder = (PAApiFolder*)self.data;
            numberLabel.stringValue = [NSString stringWithFormat:@"%ld", folder.allChildren.count];
        }
        else if ([self.data isKindOfClass:[PABeanFolder class]]) {
            PABeanFolder *folder = (PABeanFolder*)self.data;
            numberLabel.stringValue = [NSString stringWithFormat:@"%ld", folder.allChildren.count];
        }
    }
}

- (void)setBackgroundStyle:(NSBackgroundStyle)style
{
    [super setBackgroundStyle:style];
    
    
    // If the cell's text color is black, this sets it to white
    [((NSCell *)self.textField.cell) setBackgroundStyle:style];
    
    // Otherwise you need to change the color manually
    switch (style)
    {
        case NSBackgroundStyleLight:
        {
            self.imageView.image = normalImage;
            self.status.image = normalStatusImage;
            self.numberBg.image = normalBgImage;
        }
            break;
            
        case NSBackgroundStyleDark:
        {
            self.imageView.image = highlightedImage;
            self.status.image = highlightedStatusImage;
            self.numberBg.image = hightlightedBgImage;
        }
            break;
        default:
            self.imageView.image = normalImage;
            break;
    }
}
@end
