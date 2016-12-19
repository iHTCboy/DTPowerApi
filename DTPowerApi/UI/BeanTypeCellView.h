//
//  BeanTypeCellView.h
//  DTPowerApi
//
//  Created by leks on 13-1-29.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DMTableCellView.h"

@class PAField;
@class BeanTypeCellView;

@protocol BeanTypeCellDelegate <NSObject>

-(void)beanType:(BeanTypeCellView*)cell DidChangedTo:(NSString*)type forField:(PAField*)field;

@end


@interface BeanTypeCellView : DMTableCellView
{
    NSPopUpButton *popupBtn;
    PAField *field;
    NSString *lastType;
    
    id<BeanTypeCellDelegate> btDelegate;
}
@property (nonatomic, retain) IBOutlet NSPopUpButton *popupBtn;
@property (nonatomic, retain) PAField *field;
@property (nonatomic, copy) NSString *lastType;

@property (nonatomic, assign) id<BeanTypeCellDelegate> btDelegate;
@end
