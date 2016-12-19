//
//  PAField.h
//  PowerApi
//
//  Created by leks on 12-7-24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PAObject.h"
#import "PAField.h"

@class PABean;

@interface PAProperty : PAField
{
    
    NSString *linkStatusDesc;
    
    NSString  *defaultValue;
    
    PABean *parentBean;
}



//one of link success, not link, link failed
@property (nonatomic, copy) NSString *linkStatusDesc;

////one of NSString, NSInteger, NSImage, NSData
//@property (nonatomic, retain) Class propertyClass;

//one of @"", 0, nil, nil
@property (nonatomic, retain) NSString *defaultValue;
@property (nonatomic, assign) PABean *parentBean;
@end
