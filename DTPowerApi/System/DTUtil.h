//
//  DTUtil.h
//  DTLibrary
//
//  Created by Leks Zhang on 11-4-4.
//  Copyright 2011年 Leks Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IMAGE_SCALE_TYPE_FITMAX 0
#define IMAGE_SCALE_TYPE_FITMIN 1
#define IMAGE_SCALE_TYPE_FILL 2

/*工具宏定义*/
#ifndef DT_MACROS
#define DT_MACROS

//Bean用
#define DICT_ASSIGN3(pname, dict, key)\
if ([dict objectForKey:key] && !([dict objectForKey:key] == [NSNull null])) {\
self.pname = [NSString stringWithFormat:@"%@", [dict objectForKey:key]];\
}\
else {\
self.pname = @"";\
}

#define DICT_ASSIGN2(pname, dict)\
if ([dict objectForKey:@#pname] && !([dict objectForKey:@#pname] == [NSNull null])) {\
self.pname = [NSString stringWithFormat:@"%@", [dict objectForKey:@#pname]];\
}\
else {\
self.pname = @"";\
}

#define DICT_ASSIGN1(pname)\
if ([dict objectForKey:@#pname] && !([dict objectForKey:@#pname] == [NSNull null])) {\
self.pname = [NSString stringWithFormat:@"%@", [dict objectForKey:@#pname]];\
}\
else {\
self.pname = @"";\
}

#define DICT_EXPORT3(pname, md, exname)\
if(pname) [md setObject:pname forKey:@#exname];

#define DICT_EXPORT2(pname, md)\
if(pname) [md setObject:pname forKey:@#pname];

#define DICT_EXPORT1(pname)\
if(pname) [md setObject:pname forKey:@#pname];

////////////////////////////////////////////////////////////
#define IM_DICT_ASSIGN3(pname, dict, key)\
if ([dict objectForKey:key] && !([dict objectForKey:key] == [NSNull null])) {\
self.pname = [NSString stringWithFormat:@"%@", [dict objectForKey:key]];\
}\
else {\
self.pname = @"";\
}

#define IM_DICT_ASSIGN1(pname)\
if ([dict objectForKey:[@#pname lowercaseString]] && \
!([dict objectForKey:[@#pname lowercaseString]] == [NSNull null])) {\
self.pname = [NSString stringWithFormat:@"%@", [dict objectForKey:[@#pname lowercaseString]]];\
}\
else {\
self.pname = @"";\
}

#define IM_DICT_EXPORT1(pname)\
if(pname) [md setObject:pname forKey:[@#pname lowercaseString]];

////////////////////////////////////////////////////////////

#define ALERT4(title, msg, okstr, delg)\
{UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title\
message:msg\
delegate:delg\
cancelButtonTitle:okstr\
otherButtonTitles:nil];\
[alert show];\
[alert release];}

//Alert用
#define ALERT3(title, msg, okstr)\
{UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title\
message:msg\
delegate:nil\
cancelButtonTitle:okstr\
otherButtonTitles:nil];\
[alert show];\
[alert release];}

#define DEFAULT_OKSTR @"确定"
#define ALERT2(title, msg)\
{UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title\
message:msg\
delegate:nil\
cancelButtonTitle:DEFAULT_OKSTR\
otherButtonTitles:nil];\
[alert show];\
[alert release];}

#define ALERT1(msg)\
{UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil\
    message:msg\
    delegate:nil\
    cancelButtonTitle:DEFAULT_OKSTR\
    otherButtonTitles:nil];\
    [alert show];\
    [alert release];}

//动画
#define UIVIEW_ANIMATION_BEGIN3(animationid, time, sel)\
[UIView beginAnimations:animationid context:nil];\
[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];\
[UIView setAnimationDelegate:self];\
[UIView setAnimationDidStopSelector:sel];\
[UIView setAnimationDuration:time];

#define UIVIEW_ANIMATION_BEGIN2(animationid, time)\
[UIView beginAnimations:animationid context:nil];\
[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];\
[UIView setAnimationDuration:time];

#define UIVIEW_ANIMATION_END [UIView commitAnimations];

//拍照、
#define IMAGE_PICKER_CAMERA1(editable)\
{BOOL isSourceTypePhotoLibrary = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];\
if (isSourceTypePhotoLibrary) {\
UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];\
imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;\
imagePickerController.delegate = self;\
imagePickerController.allowsEditing = editable;\
[self presentModalViewController:imagePickerController animated:YES];\
[imagePickerController release];\
}}

//相册
#define IMAGE_PICKER_ALBUM1(editable)\
{BOOL isSourceTypePhotoLibrary = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];\
if (isSourceTypePhotoLibrary) {\
UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];\
imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;\
imagePickerController.delegate = self;\
imagePickerController.allowsEditing = editable;\
[self presentModalViewController:imagePickerController animated:YES];\
[imagePickerController release];\
}}
#endif


//基本设置
#define USER_DEFAULTS_GET(key) [[NSUserDefaults standardUserDefaults] objectForKey:key]
#define USER_DEFAULTS_SAVE(value, key) [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];\
[[NSUserDefaults standardUserDefaults] synchronize]

#define USER_DEFAULTS_REMOVE(key) [[NSUserDefaults standardUserDefaults] removeObjectForKey:key]
//判断是否是iPhone5
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

@interface DTUtil : NSObject
{
	
}

+ (NSString *)timeIntervalSince1970:(NSTimeInterval)secs Format:(NSString*)formatestr;
+ (NSTimeInterval)secTimeInterValSice1970:(NSString *)string Format:(NSString *)formatestr;
+ (NSString*)timeSinceDate:(NSDate*)date;
+ (NSString*)timeSinceDate:(NSString*)datestr Format:(NSString*)formatestr;
+ (NSString *)flattenHTML:(NSString *)html;
+(NSString*)filterHtml:(NSString*)str;
+ (NSString*)hashString:(NSString*)str;
+ (BOOL)isPhoneNumber:(NSString *)_text;
+ (BOOL)isMobileNumber:(NSString *)mobileNum;
+(BOOL)isHttpURL:(NSString*)_url;
+ (BOOL)checkEmailInput:(NSString *)_text;
+(BOOL)isEmptyString:(NSString *)_str;
+(BOOL)isEmptyStringFilterBlank:(NSString *)_str;
+(NSUInteger)theLenthOfStringFilterBlank:(NSString *)_str;

+ (NSString*)encodeBase64:(NSData*)input;

+(NSString*)dateStringSinceDate:(NSDate*)date Format:(NSString*)formatestr;
@end
