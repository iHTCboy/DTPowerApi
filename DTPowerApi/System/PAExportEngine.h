//
//  PAExportEngine.h
//  DTPowerApi
//
//  Created by leks on 13-2-17.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PAConstants.h"



@class PABean;
@class PAProject;
@class PAApi;

@interface PAExportEngine : NSObject
{
    
}
+(BOOL)exportBeans:(NSArray*)beans inProject:(PAProject *)project toFolderPath:(NSString *)folderPath withTemplate:(PATemplateBean)templateName;

+(BOOL)iOSExportBean:(PABean*)bean inProject:(PAProject*)project toFolderPath:(NSString*)folderPath;
+(BOOL)javaExportBean:(PABean*)bean inProject:(PAProject*)project toFolderPath:(NSString*)folderPath;

+(BOOL)iOSExportApis:(NSArray*)apis inProject:(PAProject*)project toFolderPath:(NSString *)folderPath;
+(BOOL)javaExportApis:(NSArray*)apis inProject:(PAProject*)project toFolderPath:(NSString *)folderPath;

+(NSString*)objectTypeForJsonString:(NSString*)jsonString;
+(NSArray*)arrayForJsonString:(NSString*)jsonString type:(NSString*)type;
@end
