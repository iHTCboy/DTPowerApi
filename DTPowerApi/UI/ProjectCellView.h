//
//  ProjectCellView.h
//  DTPowerApi
//
//  Created by leks on 13-1-7.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAObject.h"

@interface ProjectCellView : NSTableCellView
{
    NSImageView *numberBg;
    NSTextField *numberLabel;
    
    NSImageView *status;
    
    NSImage *normalImage;
    NSImage *highlightedImage;
    
    NSImage *normalStatusImage;
    NSImage *highlightedStatusImage;
    
    NSImage *normalBgImage;
    NSImage *hightlightedBgImage;
    
    PAObject *data;
}
@property (nonatomic, retain) IBOutlet NSImageView *numberBg;
@property (nonatomic, retain) IBOutlet NSTextField *numberLabel;

@property (nonatomic, retain) IBOutlet NSImageView *status;

@property (nonatomic, retain) NSImage *normalImage;
@property (nonatomic, retain) NSImage *highlightedImage;

@property (nonatomic, retain) NSImage *normalStatusImage;
@property (nonatomic, retain) NSImage *highlightedStatusImage;

@property (nonatomic, retain) NSImage *normalBgImage;
@property (nonatomic, retain) NSImage *hightlightedBgImage;

@property (nonatomic, retain) PAObject *data;
@end
