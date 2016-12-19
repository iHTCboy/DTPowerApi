//
//  PAExportEngine.m
//  DTPowerApi
//
//  Created by leks on 13-2-17.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PAExportEngine.h"
#import "PABean.h"
#import "PAProject.h"
#import "DTUtil.h"
#import "PAProperty.h"
#import "JSON.h"
#import "PAApi.h"
#import "PAParam.h"
#import "PAMappingEngine.h"
#import "PAParamGroup.h"
#import "PAApiResult.h"


@implementation PAExportEngine
+(BOOL)exportBeans:(NSArray*)beans inProject:(PAProject *)project toFolderPath:(NSString *)folderPath withTemplate:(PATemplateBean)templateName
{
    //create folders
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSString *platform_name = nil;
    switch (templateName) {
        case kPATemplateBeanIOS:
            platform_name = @"iOS";
            break;
        case kPATemplateBeanJAVA:
            platform_name = @"JAVA";
            break;
        default:
            break;
    }
    
    if (templateName == kPATemplateBeanIOS)
    {
        NSString *bean_path = [NSString stringWithFormat:@"%@/%@/%@/beans", folderPath, project.name, platform_name];
        [filemanager createDirectoryAtPath:bean_path withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *bean_list_path = [NSString stringWithFormat:@"%@/DTApiBeanList.plist", bean_path];
        
        NSMutableArray *bean_demo_list = [NSMutableArray arrayWithCapacity:10];
        
        NSString *baseBeanPath = [NSString stringWithFormat:@"%@/%@/%@", folderPath, project.name, platform_name];
        
        [PAExportEngine exportBaseBeantoFolderPath:baseBeanPath];
        for (int i=0; i<beans.count; i++)
        {
            PABean *b = [beans objectAtIndex:i];
            [PAExportEngine iOSExportBean:b inProject:project toFolderPath:bean_path];
            
            NSMutableDictionary *bean_demo = [NSMutableDictionary dictionaryWithCapacity:10];
            [bean_demo setObject:b.name forKey:@"name"];
            [bean_demo setObject:b.beanName forKey:@"beanName"];
            NSMutableArray *p_array = [NSMutableArray arrayWithCapacity:10];
            
            for (int i=0; i<b.properties.count; i++)
            {
                NSMutableDictionary *p_dict = [NSMutableDictionary dictionaryWithCapacity:5];
                PAProperty *p = [b.properties objectAtIndex:i];
                [p_dict setObject:p.name forKey:@"name"];
                [p_dict setObject:p.fieldName forKey:@"propertyName"];
                [p_dict setObject:p.fieldType forKey:@"propertyType"];
                [p_dict setObject:p.beanName forKey:@"beanName"];
                
                [p_array addObject:p_dict];
            }
            [bean_demo setObject:p_array forKey:@"properties"];
            [bean_demo_list addObject:bean_demo];
        } 
        
        [bean_demo_list writeToFile:bean_list_path atomically:YES];
    }
    else if (templateName == kPATemplateBeanJAVA)
    {
        NSString *bean_path = [NSString stringWithFormat:@"%@/%@/%@/com/dtapi/beans", folderPath, project.name, platform_name];
        [filemanager createDirectoryAtPath:bean_path withIntermediateDirectories:YES attributes:nil error:nil];
        for (int i=0; i<beans.count; i++)
        {
            PABean *b = [beans objectAtIndex:i];
            [PAExportEngine javaExportBean:b inProject:project toFolderPath:bean_path];
        }
    }
    return YES;
}

+(BOOL)iOSExportBean:(PABean*)bean inProject:(PAProject*)project toFolderPath:(NSString*)folderPath
{
    
    //.h
    NSString *headerTemplatePath = [[NSBundle mainBundle] pathForResource:@"iOS_Bean_Template_h" ofType:@"strings"];
    NSMutableString *headerTemplateString = [NSMutableString stringWithContentsOfFile:headerTemplatePath encoding:NSUnicodeStringEncoding error:nil];
    //.m
    NSString *srcTemplatePath = [[NSBundle mainBundle] pathForResource:@"iOS_Bean_Template_m" ofType:@"strings"];
    NSMutableString *srcTemplateString = [NSMutableString stringWithContentsOfFile:srcTemplatePath encoding:NSUnicodeStringEncoding error:nil];
    
    //Project Name
    [headerTemplateString replaceOccurrencesOfString:@"$Project.name" withString:project.name options:0 range:NSMakeRange(0, headerTemplateString.length)];
    [srcTemplateString replaceOccurrencesOfString:@"$Project.name" withString:project.name options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    //Bean Name
    [headerTemplateString replaceOccurrencesOfString:@"$Bean.beanName" withString:bean.beanName options:0 range:NSMakeRange(0, headerTemplateString.length)];
    [srcTemplateString replaceOccurrencesOfString:@"$Bean.beanName" withString:bean.beanName options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    //date
    [headerTemplateString replaceOccurrencesOfString:@"$date" withString:[DTUtil dateStringSinceDate:[NSDate date] Format:@"yy-MM-dd"] options:NSLiteralSearch range:NSMakeRange(0, headerTemplateString.length)];
    [srcTemplateString replaceOccurrencesOfString:@"$date" withString:[DTUtil dateStringSinceDate:[NSDate date] Format:@"yy-MM-dd"] options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    //Bean property variables
    NSMutableString *vars_ms = [NSMutableString stringWithCapacity:1000];
    NSMutableString *property_ms = [NSMutableString stringWithCapacity:1000];
    NSMutableString *import_ms = [NSMutableString stringWithCapacity:1000];
    NSMutableString *synthesize_ms = [NSMutableString stringWithCapacity:1000];
    NSMutableString *release_ms = [NSMutableString stringWithCapacity:1000];
    NSMutableString *assign_ms = [NSMutableString stringWithCapacity:1000];
    NSMutableArray *imported_beans = [NSMutableArray arrayWithCapacity:5];
    NSMutableString *quote_ms = [NSMutableString stringWithCapacity:100];
    NSMutableString *export_dict_ms = [NSMutableString stringWithCapacity:100];
    
    for (int i=0; i<bean.properties.count; i++)
    {
        PAProperty *p = [bean.properties objectAtIndex:i];
        [vars_ms appendString:@"\n\t"];
        [property_ms appendString:@"\n"];
        [synthesize_ms appendString:@"\n"];
        [release_ms appendString:@"\n\t"];
        [assign_ms appendString:@"\n\t\t"];
        [export_dict_ms appendString:@"\n\t"];
         
        [synthesize_ms appendFormat:@"@synthesize %@ = _%@;", p.fieldName, p.fieldName];
        [release_ms appendFormat:@"[_%@ release];", p.fieldName];
        if ([p.fieldType isEqualToString:PAFIELD_TYPE_STRING])
        {
            [vars_ms appendFormat:@"NSString *_%@;", p.fieldName];
            [property_ms appendFormat:@"@property (nonatomic, copy) NSString *%@;", p.fieldName];
            [assign_ms appendFormat:@"DTAPI_DICT_ASSIGN_STRING(%@, @\"%@\");", p.fieldName, (p.defaultValue)?p.defaultValue:@""];
            
            [export_dict_ms appendFormat:@"DTAPI_DICT_EXPORT_BASICTYPE(%@);", p.fieldName];
        }
        else if ([p.fieldType isEqualToString:PAFIELD_TYPE_NUMBER])
        {
            [vars_ms appendFormat:@"NSNumber *_%@;", p.fieldName];
            [property_ms appendFormat:@"@property (nonatomic, copy) NSNumber *%@;", p.fieldName];
            [assign_ms appendFormat:@"DTAPI_DICT_ASSIGN_NUMBER(%@, @\"%ld\");", p.fieldName, (p.defaultValue)?p.defaultValue.integerValue:0];
            [export_dict_ms appendFormat:@"DTAPI_DICT_EXPORT_BASICTYPE(%@);", p.fieldName];
        }
        else if ([p.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
        {
            [vars_ms appendFormat:@"%@ *_%@;", p.beanName, p.fieldName];
            [property_ms appendFormat:@"@property (nonatomic, retain) %@ *%@;", p.beanName, p.fieldName];
            [assign_ms appendFormat:@"self.%@ = [DTApiBaseBean objectForKey:@\"%@\" inDictionary:dict withClass:[%@ class]];", p.fieldName, p.fieldName, p.beanName];
            [export_dict_ms appendFormat:@"DTAPI_DICT_EXPORT_BEAN(%@);", p.fieldName];
            int j=0;
            for (; j<imported_beans.count; j++) {
                NSString *bname = [imported_beans objectAtIndex:j];
                if ([bname isEqualToString:p.beanName]) {
                    break;
                }
            }
            if (j==imported_beans.count) {
                [quote_ms appendFormat:@"@class %@;\n", p.beanName];
                [import_ms appendFormat:@"#import \"%@.h\"\n", p.beanName];
                [imported_beans addObject:p.beanName];
            }
            
        }
        else if ([p.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
        {
            [vars_ms appendFormat:@"NSMutableArray *_%@;", p.fieldName];
            [property_ms appendFormat:@"@property (nonatomic, retain) NSMutableArray *%@;", p.fieldName];
            if ([p.beanName isEqualToString:PAFIELD_TYPE_STRING] ||
                [p.beanName isEqualToString:PAFIELD_TYPE_NUMBER])
            {
                [assign_ms appendFormat:@"DTAPI_DICT_ASSIGN_ARRAY_BASICTYPE(%@);", p.fieldName];
                [export_dict_ms appendFormat:@"DTAPI_DICT_EXPORT_ARRAY_BASICTYPE(%@);", p.fieldName];
            }
            else
            {
                [assign_ms appendFormat:@"self.%@ = [DTApiBaseBean arrayForKey:@\"%@\" inDictionary:dict withClass:[%@ class]];", p.fieldName, p.fieldName, p.beanName];
                [export_dict_ms appendFormat:@"DTAPI_DICT_EXPORT_ARRAY_BEAN(%@);", p.fieldName];
                int j=0;
                for (; j<imported_beans.count; j++) {
                    NSString *bname = [imported_beans objectAtIndex:j];
                    if ([bname isEqualToString:p.beanName]) {
                        break;
                    }
                }
                if (j==imported_beans.count) {
                    [quote_ms appendFormat:@"@class %@;\n", p.beanName];
                    [import_ms appendFormat:@"#import \"%@.h\"\n", p.beanName];
                    [imported_beans addObject:p.beanName];
                }
            }
        }
        if (p.comment.length > 0) {
            [vars_ms appendFormat:@"\t\t\t//%@", p.comment];
        }
    }
    
    //comment
    NSString *comment = [NSString stringWithFormat:@"/*\n\t%@\n*/\n", bean.comment];
    [headerTemplateString replaceOccurrencesOfString:@"$Bean.comment" withString:comment options:NSLiteralSearch range:NSMakeRange(0, headerTemplateString.length)];
    [srcTemplateString replaceOccurrencesOfString:@"$Bean.comment" withString:comment options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    //quote
    [headerTemplateString replaceOccurrencesOfString:@"$Bean.quote" withString:quote_ms options:NSLiteralSearch range:NSMakeRange(0, headerTemplateString.length)];
    //import
    [srcTemplateString replaceOccurrencesOfString:@"$Bean.subbeans.headers.import" withString:import_ms options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    //vars
    [headerTemplateString replaceOccurrencesOfString:@"$Bean.properties.vars" withString:vars_ms options:NSLiteralSearch range:NSMakeRange(0, headerTemplateString.length)];
    //properties
    [headerTemplateString replaceOccurrencesOfString:@"$Bean.properties.property" withString:property_ms options:NSLiteralSearch range:NSMakeRange(0, headerTemplateString.length)];
    //synthesize
    [srcTemplateString replaceOccurrencesOfString:@"$Bean.properties.synthesize" withString:synthesize_ms options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    //release
    [srcTemplateString replaceOccurrencesOfString:@"$Bean.properties.release" withString:release_ms options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    //assign
    [srcTemplateString replaceOccurrencesOfString:@"$Bean.properties.assign" withString:assign_ms options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    //export dict
    [srcTemplateString replaceOccurrencesOfString:@"$Bean.properties.export" withString:export_dict_ms options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    NSLog(@"-----------------.h-----------------\n");
    NSLog(@"%@", headerTemplateString);
    NSLog(@"\n-----------------.m-----------------\n");
    NSLog(@"%@", srcTemplateString);
    
    NSString *exportHeaderPath = [NSString stringWithFormat:@"%@/%@.h", folderPath, bean.beanName];
    NSString *exportSrcPath = [NSString stringWithFormat:@"%@/%@.m", folderPath, bean.beanName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:exportHeaderPath])
    {
        ;
    }
    BOOL hExportResult = [headerTemplateString writeToFile:exportHeaderPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    BOOL mExportResult = [srcTemplateString writeToFile:exportSrcPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%d, %d", hExportResult, mExportResult);
    
    return YES;
}

+(BOOL)javaExportBean:(PABean*)bean inProject:(PAProject*)project toFolderPath:(NSString*)folderPath
{
    NSString *srcTemplatePath = [[NSBundle mainBundle] pathForResource:@"java_Bean_Template" ofType:@"strings"];
    NSMutableString *srcTemplateString = [NSMutableString stringWithContentsOfFile:srcTemplatePath encoding:NSUnicodeStringEncoding error:nil];
    
    //Project Name
    [srcTemplateString replaceOccurrencesOfString:@"$Project.name" withString:project.name options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    //Bean Name
    [srcTemplateString replaceOccurrencesOfString:@"$Bean.beanName" withString:bean.beanName options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    //date
    [srcTemplateString replaceOccurrencesOfString:@"$date" withString:[DTUtil dateStringSinceDate:[NSDate date] Format:@"yy-MM-dd"] options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    NSMutableString *vars_ms = [NSMutableString stringWithCapacity:1000];
    NSMutableString *import_ms = [NSMutableString stringWithCapacity:1000];
    NSMutableString *synthesize_ms = [NSMutableString stringWithCapacity:1000];
    NSMutableArray *imported_beans = [NSMutableArray arrayWithCapacity:5];
    BOOL hasArray = NO;
    
    for (int i=0; i<bean.properties.count; i++)
    {
        PAProperty *p = [bean.properties objectAtIndex:i];
        [vars_ms appendString:@"\n\t"];
        [synthesize_ms appendString:@"\n"];
        
        if ([p.fieldType isEqualToString:PAFIELD_TYPE_STRING])
        {
            [vars_ms appendFormat:@"String %@;", p.fieldName];
            
            //setter 
            [synthesize_ms appendFormat:@"\tpublic void set%@(String %@) {\n\t\tthis.%@ = %@;\n\t}\n", [PAExportEngine upperFirstLetter:p.fieldName], p.fieldName, p.fieldName, p.fieldName];
            //getter
            [synthesize_ms appendFormat:@"\tpublic String get%@() {\n\t\t return %@;\n\t}\n", [PAExportEngine upperFirstLetter:p.fieldName], p.fieldName];
        }
        else if ([p.fieldType isEqualToString:PAFIELD_TYPE_NUMBER])
        {
            [vars_ms appendFormat:@"Number %@;", p.fieldName];
        
            //setter
            [synthesize_ms appendFormat:@"\tpublic void set%@(Number %@) {\n\t\tthis.%@ = %@;\n\t}\n", [PAExportEngine upperFirstLetter:p.fieldName], p.fieldName, p.fieldName, p.fieldName];
            //getter
            [synthesize_ms appendFormat:@"\tpublic Number get%@() {\n\t\t return %@;\n\t}\n", [PAExportEngine upperFirstLetter:p.fieldName], p.fieldName];
        }
        else if ([p.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
        {
            [vars_ms appendFormat:@"%@ %@;", p.beanName, p.fieldName];
            
            //setter
            [synthesize_ms appendFormat:@"\tpublic void set%@(%@ %@) {\n\t\tthis.%@ = %@;\n\t}\n", [PAExportEngine upperFirstLetter:p.fieldName], p.beanName, p.fieldName, p.fieldName, p.fieldName];
            //getter
            [synthesize_ms appendFormat:@"\tpublic %@ get%@() {\n\t\t return %@;\n\t}\n", p.beanName, [PAExportEngine upperFirstLetter:p.fieldName], p.fieldName];
            
            int j=0;
            for (; j<imported_beans.count; j++) {
                NSString *bname = [imported_beans objectAtIndex:j];
                if ([bname isEqualToString:p.beanName]) {
                    break;
                }
            }
            if (j==imported_beans.count) {
                [import_ms appendFormat:@"import com.dtapi.beans.%@;\n", p.beanName];
                [imported_beans addObject:p.beanName];
            }
        }
        else if ([p.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
        {
            hasArray = YES;
            [vars_ms appendFormat:@"ArrayList<%@> %@;", p.beanName, p.fieldName];
            
            //setter
            [synthesize_ms appendFormat:@"\tpublic void set%@(ArrayList<%@> %@) {\n\t\tthis.%@ = %@;\n\t}\n", [PAExportEngine upperFirstLetter:p.fieldName], p.beanName, p.fieldName, p.fieldName, p.fieldName];
            //getter
            [synthesize_ms appendFormat:@"\tpublic ArrayList<%@> get%@() {\n\t\t return %@;\n\t}\n", p.beanName, [PAExportEngine upperFirstLetter:p.fieldName], p.fieldName];
            
            if ([p.beanName isEqualToString:PAFIELD_TYPE_STRING] ||
                [p.beanName isEqualToString:PAFIELD_TYPE_NUMBER])
            {
                
            }
            else
            {
                int j=0;
                for (; j<imported_beans.count; j++) {
                    NSString *bname = [imported_beans objectAtIndex:j];
                    if ([bname isEqualToString:p.beanName]) {
                        break;
                    }
                }
                if (j==imported_beans.count) {
                    [import_ms appendFormat:@"import com.dtapi.beans.%@;\n", p.beanName];
                    [imported_beans addObject:p.beanName];
                }
            }
        }
        
        if (p.comment.length > 0) {
            [vars_ms appendFormat:@"\t\t\t//%@", p.comment];
        }
    }
    
    if (hasArray) [import_ms appendString:@"import java.util.ArrayList;\n"];
    //import
    [srcTemplateString replaceOccurrencesOfString:@"$Bean.subbeans.headers.import" withString:import_ms options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    //vars
    [srcTemplateString replaceOccurrencesOfString:@"$Bean.properties.vars" withString:vars_ms options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    //synthesize
    [srcTemplateString replaceOccurrencesOfString:@"$Bean.properties.synthesize" withString:synthesize_ms options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    NSString *exportSrcPath = [NSString stringWithFormat:@"%@/%@.java", folderPath, bean.beanName];
    BOOL mExportResult = [srcTemplateString writeToFile:exportSrcPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    return YES;
}

+(void)exportBaseBeantoFolderPath:(NSString*)folderPath
{
    //.h
    NSString *headerTemplatePath = [[NSBundle mainBundle] pathForResource:@"iOS_Bean_Template_Base_h" ofType:@"strings"];
    NSMutableString *headerTemplateString = [NSMutableString stringWithContentsOfFile:headerTemplatePath encoding:NSUnicodeStringEncoding error:nil];
    //.m
    NSString *srcTemplatePath = [[NSBundle mainBundle] pathForResource:@"iOS_Bean_Template_Base_m" ofType:@"strings"];
    NSMutableString *srcTemplateString = [NSMutableString stringWithContentsOfFile:srcTemplatePath encoding:NSUnicodeStringEncoding error:nil];
    
    NSString *exportHeaderPath = [NSString stringWithFormat:@"%@/DTApiBaseBean.h", folderPath];
    NSString *exportSrcPath = [NSString stringWithFormat:@"%@/DTApiBaseBean.m", folderPath];
    
    [headerTemplateString writeToFile:exportHeaderPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [srcTemplateString writeToFile:exportSrcPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark -
#pragma mark ***** Adding and Removing Objects under NSUndoManager *****

+(NSString*)objectTypeForJsonString:(NSString*)jsonString
{
    id obj = [jsonString JSONValue];
    if (!obj)
    {
        if ([DTUtil isHttpURL:jsonString])
        {
            return PAOBJECT_NAME_NEW_API;
        }
        
        NSArray *array = [jsonString componentsSeparatedByString:@"&"];
        if (array.count > 0)
        {
            for (int i=0; i<array.count; i++)
            {
                NSString *pairString = [array objectAtIndex:i];
                NSArray *pair = [pairString componentsSeparatedByString:@"="];
                if (pair.count == 2) {
                    return PAOBJECT_NAME_NEW_PARAM;
                };
            }
        }
        
        return nil;
    }
    
    if ([obj isKindOfClass:[NSArray class]])
    {
        NSArray *obj_array = obj;
        if (obj_array.count > 0)
        {
            id array_item = [obj_array objectAtIndex:0];
            if ([array_item isKindOfClass:[NSDictionary class]])
            {
                NSString *obj_type = [array_item objectForKey:PAOBJECT_SOURCE_TYPE];
                if (!obj_type)
                {
                    return PAOBJECT_NAME_NEW_BEAN_ARRAY;
                }
                else if ([obj_type isEqualToString:PAOBJECT_NAME_PROJECT])
                {
                    return PAOBJECT_NAME_PROJECT_ARRAY;
                }
                else if ([obj_type isEqualToString:PAOBJECT_NAME_BEAN])
                {
                    return PAOBJECT_NAME_BEAN_ARRAY;
                }
                else if ([obj_type isEqualToString:PAOBJECT_NAME_API])
                {
                    return PAOBJECT_NAME_API_ARRAY;
                }
                else if ([obj_type isEqualToString:PAOBJECT_NAME_PARAM])
                {
                    return PAOBJECT_NAME_PARAM_ARRAY;
                }
                else if ([obj_type isEqualToString:PAOBJECT_NAME_PROPERTY])
                {
                    return PAOBJECT_NAME_PROPERTY_ARRAY;
                }
                else if ([obj_type isEqualToString:PAOBJECT_NAME_BEANFOLDER])
                {
                    return PAOBJECT_NAME_BEANFOLDER_ARRAY;
                }
                else if ([obj_type isEqualToString:PAOBJECT_NAME_APIFOLDER])
                {
                    return PAOBJECT_NAME_APIFOLDER_ARRAY;
                }
                else if ([obj_type isEqualToString:PAOBJECT_NAME_APIRESULT])
                {
                    return PAOBJECT_NAME_APIRESULT_ARRAY;
                }
                else if ([obj_type isEqualToString:PAOBJECT_NAME_PARAMGROUP])
                {
                    return PAOBJECT_NAME_PARAMGROUP_ARRAY;
                }
                else
                {
                    return nil;
                }
            }
        }
    }
    else if ([obj isKindOfClass:[NSDictionary class]])
    {
        NSString *obj_type = [obj objectForKey:PAOBJECT_SOURCE_TYPE];
        if (!obj_type)
        {
            return PAOBJECT_NAME_NEW_BEAN;
        }
        else if ([obj_type isEqualToString:PAOBJECT_NAME_PROJECT] ||
                 [obj_type isEqualToString:PAOBJECT_NAME_BEAN] ||
                 [obj_type isEqualToString:PAOBJECT_NAME_API] ||
                 [obj_type isEqualToString:PAOBJECT_NAME_PARAM] ||
                 [obj_type isEqualToString:PAOBJECT_NAME_PROPERTY] ||
                 [obj_type isEqualToString:PAOBJECT_NAME_BEANFOLDER] ||
                 [obj_type isEqualToString:PAOBJECT_NAME_APIFOLDER] ||
                 [obj_type isEqualToString:PAOBJECT_NAME_APIRESULT] ||
                 [obj_type isEqualToString:PAOBJECT_NAME_PARAMGROUP])
        {
            return obj_type;
        }
        else
        {
            return PAOBJECT_NAME_NEW_BEAN;
        }
    }
    
    return nil;
}

+(BOOL)iOSExportApis:(NSArray*)apis inProject:(PAProject*)project toFolderPath:(NSString *)folderPath
{
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSString *api_path = [NSString stringWithFormat:@"%@/%@/iOS/api", folderPath, project.name];
    
    [filemanager createDirectoryAtPath:api_path withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *exportHeaderPath = [NSString stringWithFormat:@"%@/DTApiWrapper.h", api_path];
    NSString *exportSrcPath = [NSString stringWithFormat:@"%@/DTApiWrapper.m", api_path];
    NSString *demoListPath = [NSString stringWithFormat:@"%@/DTApiDemoList.plist", api_path];
    NSString *exportHeaderPathCaller = [NSString stringWithFormat:@"%@/DTApiCaller.h", api_path];
    NSString *exportSrcPathCaller = [NSString stringWithFormat:@"%@/DTApiCaller.m", api_path];
    //wrapper.h
    NSString *headerTemplatePath = [[NSBundle mainBundle] pathForResource:@"iOS_ApiWrapper_Template_h" ofType:@"strings"];
    NSMutableString *headerTemplateString = [NSMutableString stringWithContentsOfFile:headerTemplatePath encoding:NSUnicodeStringEncoding error:nil];
    //wrapper.m
    NSString *srcTemplatePath = [[NSBundle mainBundle] pathForResource:@"iOS_ApiWrapper_Template_m" ofType:@"strings"];
    NSMutableString *srcTemplateString = [NSMutableString stringWithContentsOfFile:srcTemplatePath encoding:NSUnicodeStringEncoding error:nil];
    
    //Project Name
    [headerTemplateString replaceOccurrencesOfString:@"$Project.name" withString:project.name options:0 range:NSMakeRange(0, headerTemplateString.length)];
    [srcTemplateString replaceOccurrencesOfString:@"$Project.name" withString:project.name options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    //date
    [headerTemplateString replaceOccurrencesOfString:@"$date" withString:[DTUtil dateStringSinceDate:[NSDate date] Format:@"yy-MM-dd"] options:NSLiteralSearch range:NSMakeRange(0, headerTemplateString.length)];
    [srcTemplateString replaceOccurrencesOfString:@"$date" withString:[DTUtil dateStringSinceDate:[NSDate date] Format:@"yy-MM-dd"] options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    //wrapper.h
    NSString *headerTemplatePath_caller = [[NSBundle mainBundle] pathForResource:@"iOS_ApiCaller_Template_h" ofType:@"strings"];
    NSMutableString *headerTemplateString_caller = [NSMutableString stringWithContentsOfFile:headerTemplatePath_caller encoding:NSUnicodeStringEncoding error:nil];
    //wrapper.m
    NSString *srcTemplatePath_caller = [[NSBundle mainBundle] pathForResource:@"iOS_ApiCaller_Template_m" ofType:@"strings"];
    NSMutableString *srcTemplateString_caller = [NSMutableString stringWithContentsOfFile:srcTemplatePath_caller encoding:NSUnicodeStringEncoding error:nil];
    
    //Project Name
    [headerTemplateString_caller replaceOccurrencesOfString:@"$Project.name" withString:project.name options:0 range:NSMakeRange(0, headerTemplateString_caller.length)];
    [srcTemplateString_caller replaceOccurrencesOfString:@"$Project.name" withString:project.name options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString_caller.length)];
    
    //date
    [headerTemplateString_caller replaceOccurrencesOfString:@"$date" withString:[DTUtil dateStringSinceDate:[NSDate date] Format:@"yy-MM-dd"] options:NSLiteralSearch range:NSMakeRange(0, headerTemplateString_caller.length)];
    [srcTemplateString_caller replaceOccurrencesOfString:@"$date" withString:[DTUtil dateStringSinceDate:[NSDate date] Format:@"yy-MM-dd"] options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString_caller.length)];
    
    
    NSMutableString *declare_ms = [NSMutableString stringWithCapacity:1000];
    NSMutableString *implement_ms = [NSMutableString stringWithCapacity:1000];
    NSMutableArray *demoList = [NSMutableArray arrayWithCapacity:100];
    
    NSMutableString *declare_ms_caller = [NSMutableString stringWithCapacity:1000];
    NSMutableString *implement_ms_caller = [NSMutableString stringWithCapacity:1000];
    
    NSMutableString *demo_run_body = [NSMutableString stringWithCapacity:1000];
    NSMutableArray *demo_run_parts = [NSMutableArray arrayWithCapacity:10];
    
    NSMutableString *macros = [NSMutableString stringWithCapacity:200];
    [macros appendFormat:@"#define kProjectBaseUrl @\"%@\"\n\n", project.baseUrl];
    
    //common params, add to wrapper
    NSDictionary *commonParams = [self iOSCommonParamsForProject:project];
    NSString *common_implement = [commonParams objectForKey:@"implement"];
    NSString *common_method_name = [commonParams objectForKey:@"declare"];
    NSString *common_comments = [commonParams objectForKey:@"comment"];
    NSString *common_var_decalre = [commonParams objectForKey:@"var_decalre"];
    NSString *common_property_declare = [commonParams objectForKey:@"property_declare"];
    NSString *common_syn_declare = [commonParams objectForKey:@"syn_declare"];
    NSString *common_dealloc_declare = [commonParams objectForKey:@"dealloc_declare"];
    [declare_ms appendFormat:@"%@\n%@\n%@;\n\n", common_var_decalre,common_comments, common_property_declare];
    [declare_ms appendFormat:@"%@;\n", common_method_name];
    [implement_ms appendFormat:@"%@\n\n%@\n\n%@\n", common_syn_declare, common_dealloc_declare, common_implement];
    
    [demo_run_body appendString:@"-(ASIHTTPRequest*)demoRunApi:(NSString*)apiName group:(NSString*)groupName delegate:(id)delegate\n{"];
    
    for (int i=0; i<apis.count; i++)
    {
        PAApi *a = [apis objectAtIndex:i];
        if (a.selectedParamGroup.getParams.count == 0 &&
            a.selectedParamGroup.postDatas.count == 0) {
            continue ;
        }
        
        //macro
        [macros appendFormat:@"#define kRequest_%@ @\"%@\"\n", a.macroName, a.name];
        //wrapper
        NSDictionary *wrapper = [PAExportEngine iOSWrapperMethodForApi:a];
        NSString *implement = [wrapper objectForKey:@"implement"];
        NSString *declare = [wrapper objectForKey:@"declare"];
        NSString *comment = [wrapper objectForKey:@"comment"];
        
        [declare_ms appendFormat:@"%@\n%@;\n\n", comment, declare];
        [implement_ms appendFormat:@"%@\n\n", implement];
        
        //caller
        NSDictionary *caller = [PAExportEngine iOSCallerMethodForApi:a];
        NSString *implement_caller = [caller objectForKey:@"implement"];
        NSString *declare_caller = [caller objectForKey:@"declare"];
        NSString *comment_caller = [caller objectForKey:@"comment"];
        NSArray *demo_calls = [caller objectForKey:@"demo_calls"];
        
        [demo_run_parts addObjectsFromArray:demo_calls];
        [declare_ms_caller appendFormat:@"%@\n%@;\n\n", comment_caller, declare_caller];
        [implement_ms_caller appendFormat:@"%@\n\n", implement_caller];
        
        NSMutableDictionary *api_dict = [NSMutableDictionary dictionaryWithCapacity:10];
        for (int i=0; i<a.paramGroups.count; i++)
        {
            PAParamGroup *pg = [a.paramGroups objectAtIndex:i];
            [api_dict setObject:a.name forKey:@"name"];
            [api_dict setObject:pg.name forKey:@"groupName"];
            [demoList addObject:api_dict];
        }
    }
    
    [demo_run_body appendString:@"\n\t//Setting common params, you may do this some where else\n"];
    
    for (int i=0; i<project.commonGetParams.count; i++)
    {
        PAParam *p = [project.commonGetParams objectAtIndex:i];
        [demo_run_body appendFormat:@"\n\t_dtApiWrapper.%@ = @\"%@\";", p.paramKey, p.paramValue];
    }
    
    for (int i=0; i<project.commonPostDatas.count; i++)
    {
        PAParam *p = [project.commonPostDatas objectAtIndex:i];
        [demo_run_body appendFormat:@"\n\t_dtApiWrapper.p_%@ = @\"%@\";", p.paramKey, p.paramValue];
    }
    
    [demo_run_body appendString:@"\n\n"];
    
    for (int i=0; i<demo_run_parts.count; i++)
    {
        [demo_run_body appendString:@"\t"];
        
        if (i != 0) {
            [demo_run_body appendString:@"else "];
        }
        
        [demo_run_body appendString:[demo_run_parts objectAtIndex:i]];
        [demo_run_body appendString:@"\n"];
    }
    
    [demo_run_body appendString:@"\treturn nil;\n}"];

    
    
    
//wrapper
    //declares
    [headerTemplateString replaceOccurrencesOfString:@"$Api.decalres" withString:declare_ms options:NSLiteralSearch range:NSMakeRange(0, headerTemplateString.length)];
    
    //implements
    [srcTemplateString replaceOccurrencesOfString:@"$Api.implementations" withString:implement_ms options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    [headerTemplateString writeToFile:exportHeaderPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [srcTemplateString writeToFile:exportSrcPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
//caller
    //$Api.macros
    [headerTemplateString_caller replaceOccurrencesOfString:@"$Api.macros" withString:macros options:NSLiteralSearch range:NSMakeRange(0, headerTemplateString_caller.length)];
    
    //declares
    [headerTemplateString_caller replaceOccurrencesOfString:@"$Api.decalres" withString:declare_ms_caller options:NSLiteralSearch range:NSMakeRange(0, headerTemplateString_caller.length)];
    
    //implements
    [srcTemplateString_caller replaceOccurrencesOfString:@"$Api.implementations" withString:implement_ms_caller options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString_caller.length)];
    
    //demo_method
    [srcTemplateString_caller replaceOccurrencesOfString:@"$Api.run_demo_method" withString:demo_run_body options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString_caller.length)];
    
    [headerTemplateString_caller writeToFile:exportHeaderPathCaller atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [srcTemplateString_caller writeToFile:exportSrcPathCaller atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    [demoList writeToFile:demoListPath atomically:YES];
    return YES;
}

//wrapper
+(NSDictionary*)iOSWrapperMethodForApi:(PAApi*)api
{
    NSMutableString *all = [NSMutableString stringWithCapacity:200];
    NSMutableString *method_name = [NSMutableString stringWithCapacity:200];
    NSMutableString *get_assigns = [NSMutableString stringWithCapacity:500];
    NSMutableString *post_assigns = [NSMutableString stringWithCapacity:500];
    NSMutableString *comments = [NSMutableString stringWithCapacity:500];
    
    [comments appendFormat:@"/*\n\tApi:%@, %@\n", api.name, api.comment];
    
    [method_name appendFormat:@"-(NSDictionary*)%@",api.exportPrefix];
    BOOL firstParam = YES;
    
    for (int i=0; i<api.selectedParamGroup.getParams.count; i++)
    {
        PAParam *p = [api.selectedParamGroup.getParams objectAtIndex:i];
        NSString *type = [PAExportEngine exportTypeNameForParamType:p.paramType withTemplate:kPATemplateBeanIOS];
        
        if ([api.project paramExists:p isPost:NO])
        {
            continue ;
        }
        
        if (firstParam)
        {
            [method_name appendFormat:@"%@:(%@*)%@ ", [PAExportEngine upperFirstLetter:p.paramKey], type, p.paramKey];
            firstParam = NO;
        }
        else
        {
            [method_name appendFormat:@"%@:(%@*)%@ ", p.paramKey, type, p.paramKey];
        }
        
        [get_assigns appendFormat:@"\n\tif (%@) [getParams setObject:%@ forKey:@\"%@\"];", p.paramKey, p.paramKey, p.paramKey];
        
        if (p.comment)
        {
            [comments appendFormat:@"\t@param GET  %@ %@\n", p.paramKey, p.comment];
        }
        else
        {
            [comments appendFormat:@"\t@param GET  %@ \n", p.paramKey];
        }
    }
    
    for (int i=0; i<api.selectedParamGroup.postDatas.count; i++)
    {
        PAParam *p = [api.selectedParamGroup.postDatas objectAtIndex:i];
        NSString *type = [PAExportEngine exportTypeNameForParamType:p.paramType withTemplate:kPATemplateBeanIOS];
        if ([api.project paramExists:p isPost:YES])
        {
            continue ;
        }
        
        if (firstParam)
        {
            [method_name appendFormat:@"%@:(%@*)p_%@ ", [PAExportEngine upperFirstLetter:p.paramKey], type, p.paramKey];
            firstParam = NO;
        }
        else
        {
            [method_name appendFormat:@"p_%@:(%@*)p_%@ ", p.paramKey, type, p.paramKey];
        }
        
        [post_assigns appendFormat:@"\n\tif (p_%@) [postDatas setObject:p_%@ forKey:@\"%@\"];", p.paramKey, p.paramKey, p.paramKey];
        
        if (p.comment)
        {
            [comments appendFormat:@"\t@param POST %@ %@\n", p.paramKey, p.comment];
        }
        else
        {
            [comments appendFormat:@"\t@param POST %@ \n", p.paramKey];
        }
    }
    
    [comments appendString:@"*/"];
    
    NSString *return_ms = [NSString stringWithFormat:@"\treturn [self wrapCommonParamsWithGetParams:getParams postDatas:postDatas];"];
    NSString *local_define = @"\n\tNSMutableDictionary *getParams = [NSMutableDictionary dictionaryWithCapacity:5];\n\tNSMutableDictionary *postDatas = [NSMutableDictionary dictionaryWithCapacity:5];\n";
    [all appendFormat:@"%@\n%@\n{%@\n%@\n\t%@\n\n%@\n}",comments, method_name, local_define, get_assigns, post_assigns, return_ms];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:all, @"implement", method_name, @"declare", comments, @"comment", nil];
}

+(NSDictionary*)iOSCallerMethodForApi:(PAApi*)api
{
    NSMutableString *all = [NSMutableString stringWithCapacity:200];
    NSMutableString *method_name = [NSMutableString stringWithCapacity:200];
    NSMutableString *wrapper_def = [NSMutableString stringWithCapacity:200];
    NSMutableString *comments = [NSMutableString stringWithCapacity:500];
    
    NSMutableArray *demo_calls = [NSMutableArray arrayWithCapacity:10];
    NSMutableString *call_api_template = [NSMutableString stringWithCapacity:100];
    NSMutableString *call_body = [NSMutableString stringWithCapacity:100];
    
    [comments appendFormat:@"/*\n\tApi:%@, %@\n", api.name, api.comment];
    [method_name appendFormat:@"-(ASIHTTPRequest*)%@",api.exportPrefix];
    
    if ([api.url isEqualToString:@"${PROJECT_BASEURL}"]) {
        [call_body appendFormat:@"[self %@", api.exportPrefix];
    }
    else
    {
        [call_body appendFormat:@"[self %@", api.exportPrefix];
    }
    
    
    [wrapper_def appendFormat:@"NSDictionary *wrapper = [_dtApiWrapper %@", api.exportPrefix];

    [call_api_template appendFormat:@"if ([apiName isEqualToString:@\"%@\"] && [groupName isEqualToString:$$Api.groupName]) {\n\t\treturn $$Api.callerbody;\n\t}", api.name];
    
    BOOL firstParam = YES;
    
    for (int i=0; i<api.selectedParamGroup.getParams.count; i++)
    {
        PAParam *p = [api.selectedParamGroup.getParams objectAtIndex:i];
        NSString *type = [PAExportEngine exportTypeNameForParamType:p.paramType withTemplate:kPATemplateBeanIOS];
        
        if ([api.project paramExists:p isPost:NO])
        {
            continue ;
        }
        
        if (firstParam)
        {
            [method_name appendFormat:@"%@:(%@*)%@ ", [PAExportEngine upperFirstLetter:p.paramKey], type, p.paramKey];
            [wrapper_def appendFormat:@"%@:%@ ", [PAExportEngine upperFirstLetter:p.paramKey], p.paramKey];
            [call_body appendFormat:@"%@:$$%@ ", [PAExportEngine upperFirstLetter:p.paramKey], p.paramKey];
            firstParam = NO;
        }
        else
        {
            [method_name appendFormat:@"%@:(%@*)%@ ", p.paramKey, type, p.paramKey];
            [wrapper_def appendFormat:@"%@:%@ ", p.paramKey, p.paramKey];
            [call_body appendFormat:@"%@:$$%@ ", p.paramKey, p.paramKey];
        }
        
        if (p.comment)
        {
            [comments appendFormat:@"\t@param GET  %@ %@\n", p.paramKey, p.comment];
        }
        else
        {
            [comments appendFormat:@"\t@param GET  %@ \n", p.paramKey];
        }
        
    }
    
    for (int i=0; i<api.selectedParamGroup.postDatas.count; i++)
    {
        PAParam *p = [api.selectedParamGroup.postDatas objectAtIndex:i];
        NSString *type = [PAExportEngine exportTypeNameForParamType:p.paramType withTemplate:kPATemplateBeanIOS];
        
        if ([api.project paramExists:p isPost:YES])
        {
            continue ;
        }
        
        if (firstParam)
        {
            [method_name appendFormat:@"%@:(%@*)p_%@ ", [PAExportEngine upperFirstLetter:p.paramKey], type, p.paramKey];
            [wrapper_def appendFormat:@"%@:p_%@ ", [PAExportEngine upperFirstLetter:p.paramKey], p.paramKey];
            [call_body appendFormat:@"p_%@:$$p_%@ ", [PAExportEngine upperFirstLetter:p.paramKey], p.paramKey];
            firstParam = NO;
        }
        else
        {
            [method_name appendFormat:@"p_%@:(%@*)p_%@ ", p.paramKey, type, p.paramKey];
            [wrapper_def appendFormat:@"p_%@:p_%@ ", p.paramKey, p.paramKey];
            [call_body appendFormat:@"p_%@:$$p_%@ ", p.paramKey, p.paramKey];
        }
        
        if (p.comment)
        {
            [comments appendFormat:@"\t@param POST %@ %@\n", p.paramKey, p.comment];
        }
        else
        {
            [comments appendFormat:@"\t@param POST %@ \n", p.paramKey];
        }
    }
    [comments appendString:@"*/"];
    [call_body appendString:@"delegate:delegate]"];
    
    for (int i=0; i<api.paramGroups.count; i++)
    {
        NSMutableString *tmp_call = [NSMutableString stringWithString:call_api_template];
        NSMutableString *tmp_body = [NSMutableString stringWithString:call_body];
        
        PAParamGroup *pg = [api.paramGroups objectAtIndex:i];
        for (int j=0; j<pg.getParams.count; j++)
        {
            PAParam *param = [pg.getParams objectAtIndex:j];
            NSString *sign = [NSString stringWithFormat:@"$$%@", param.paramKey];
            NSString *pv = [param.paramValue stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            NSString *replace_paramName = [NSString stringWithFormat:@"@\"%@\"", pv];
            [tmp_body replaceOccurrencesOfString:sign withString:replace_paramName options:NSLiteralSearch range:NSMakeRange(0, tmp_body.length)];
        }
        
        for (int j=0; j<pg.postDatas.count; j++)
        {
            PAParam *param = [pg.postDatas objectAtIndex:j];
            NSString *sign = [NSString stringWithFormat:@"$$p_%@", param.paramKey];
            if ([param.paramType isEqualToString:PAPARAM_TYPE_FILE])
            {
                NSArray *tmp = [param.filename componentsSeparatedByString:@"/"];
                NSString *filename = [tmp lastObject];
                if (filename.length > 0)
                {
                    tmp = [filename componentsSeparatedByString:@"."];
                    if (tmp.count > 0)
                    {
                        NSMutableString *file_prefix = [NSMutableString stringWithCapacity:10];
                        NSString *file_suffix = @"";
                        if (tmp.count == 1) {
                            file_prefix = [tmp objectAtIndex:0];
                        }
                        else
                        {
                            for (int i=0; i<tmp.count-1; i++) {
                                if (i != 0) {
                                    [file_prefix appendString:@"."];
                                }
                                [file_prefix appendString:[tmp objectAtIndex:i]];
                            }
                            file_suffix = [tmp lastObject];
                        }
                        
                        NSString *replace_paramValue = [NSString stringWithFormat:@"[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@\"%@\" ofType:@\"%@\"]]", file_prefix, file_suffix];
                        [tmp_body replaceOccurrencesOfString:sign withString:replace_paramValue options:NSLiteralSearch range:NSMakeRange(0, tmp_body.length)];
                    }
                    else
                    {
                        [tmp_body replaceOccurrencesOfString:sign withString:@"nil" options:NSLiteralSearch range:NSMakeRange(0, tmp_body.length)];
                    }
                    
                }
                else
                {
                    [tmp_body replaceOccurrencesOfString:sign withString:@"nil" options:NSLiteralSearch range:NSMakeRange(0, tmp_body.length)];
                }
            }
            else
            {
                NSString *pv = [param.paramValue stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
                NSString *replace_paramName = [NSString stringWithFormat:@"@\"%@\"", pv];
                [tmp_body replaceOccurrencesOfString:sign withString:replace_paramName options:NSLiteralSearch range:NSMakeRange(0, tmp_body.length)];
            }
        }
        
        NSString *replace_groupName = [NSString stringWithFormat:@"@\"%@\"", pg.name];
        
        [tmp_call replaceOccurrencesOfString:@"$$Api.groupName" withString:replace_groupName options:NSLiteralSearch range:NSMakeRange(0, tmp_call.length)];
        [tmp_call replaceOccurrencesOfString:@"$$Api.callerbody" withString:tmp_body options:NSLiteralSearch range:NSMakeRange(0, tmp_call.length)];
        
        [demo_calls addObject:tmp_call];
    }
    
    [method_name appendString:@"delegate:(id)delegate"];
    [wrapper_def appendFormat:@"];"];
    
    NSString *macro_name = [NSString stringWithFormat:@"kRequest_%@", api.macroName];
    NSString *burl = nil;
    if ([[api.url uppercaseString] isEqualToString:@"${PROJECT_BASEURL}"])
    {
        if (api.path.length == 0) {
            burl = @"kProjectBaseUrl";
        }
        else
        {
            burl = [NSString stringWithFormat:@"@\"%@%@\"", api.project.baseUrl, api.path];
        }
    }
    else
    {
        burl = [NSString stringWithFormat:@"@\"%@%@\"", api.url, api.path];
    }
    NSString *return_ms = [NSString stringWithFormat:@"\treturn [DTApiCaller requestWithName:%@ baseUrl:%@ getParams:[wrapper objectForKey:@\"getParams\"] postDatas:[wrapper objectForKey:@\"postDatas\"] delegate:delegate];", macro_name, burl];
    
    [all appendFormat:@"%@\n%@\n{\n\t%@\n\n\t%@\n}",comments, method_name, wrapper_def, return_ms];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:all, @"implement", method_name, @"declare", comments, @"comment", demo_calls, @"demo_calls", nil];
}

+(NSDictionary*)iOSCommonParamsForProject:(PAProject*)project
{
    NSMutableString *all = [NSMutableString stringWithCapacity:200];
    
    NSMutableString *var_decalre = [NSMutableString stringWithCapacity:100];
    NSMutableString *property_declare = [NSMutableString stringWithCapacity:100];
    NSMutableString *syn_declare = [NSMutableString stringWithCapacity:100];
    NSMutableString *dealloc_declare = [NSMutableString stringWithCapacity:100];
    
    NSMutableString *method_name = [NSMutableString stringWithCapacity:200];
    NSMutableString *get_assigns = [NSMutableString stringWithCapacity:500];
    NSMutableString *post_assigns = [NSMutableString stringWithCapacity:500];
    NSMutableString *comments = [NSMutableString stringWithCapacity:500];
    
    [var_decalre appendString:@"{\n"];
    [dealloc_declare appendString:@"-(void)dealloc\n{\n"];
     
    [comments appendFormat:@"/*\n\tProject Name:%@\n", project.name];
    
    [method_name appendFormat:@"-(NSDictionary*)commonParams"];
    BOOL firstParam = YES;
    
    for (int i=0; i<project.commonGetParams.count; i++)
    {
        PAParam *p = [project.commonGetParams objectAtIndex:i];
        NSString *type = [PAExportEngine exportTypeNameForParamType:p.paramType withTemplate:kPATemplateBeanIOS];
        
        if (firstParam)
        {
//            [method_name appendFormat:@"%@:(%@*)%@ ", [PAExportEngine upperFirstLetter:p.paramKey], type, p.paramKey];
            firstParam = NO;
        }
        else
        {
//            [method_name appendFormat:@"%@:(%@*)%@ ", p.paramKey, type, p.paramKey];
        }
        
        [get_assigns appendFormat:@"\n\tif (_%@) [getParams setObject:_%@ forKey:@\"%@\"];", p.paramKey, p.paramKey, p.paramKey];
        
        if (p.comment)
        {
            [comments appendFormat:@"\t@param GET  %@ %@\n", p.paramKey, p.comment];
        }
        else
        {
            [comments appendFormat:@"\t@param GET  %@ \n", p.paramKey];
        }
        
        [var_decalre appendFormat:@"\t%@ *_%@;\n", type, p.paramKey];
        [property_declare appendFormat:@"@property (nonatomic, copy) %@ *%@;\n", type, p.paramKey];
        [syn_declare appendFormat:@"@synthesize %@ = _%@;\n", p.paramKey, p.paramKey];
        [dealloc_declare appendFormat:@"\t[_%@ release];\n", p.paramKey];
    }
    
    for (int i=0; i<project.commonPostDatas.count; i++)
    {
        PAParam *p = [project.commonPostDatas objectAtIndex:i];
        NSString *type = [PAExportEngine exportTypeNameForParamType:p.paramType withTemplate:kPATemplateBeanIOS];
        
        if (firstParam)
        {
//            [method_name appendFormat:@"%@:(%@*)p_%@ ", [PAExportEngine upperFirstLetter:p.paramKey], type, p.paramKey];
            firstParam = NO;
        }
        else
        {
//            [method_name appendFormat:@"p_%@:(%@*)p_%@ ", p.paramKey, type, p.paramKey];
        }
        
        [post_assigns appendFormat:@"\n\tif (_p_%@) [postDatas setObject:_p_%@ forKey:@\"%@\"];", p.paramKey, p.paramKey, p.paramKey];
        
        if (p.comment)
        {
            [comments appendFormat:@"\t@param POST %@ %@\n", p.paramKey, p.comment];
        }
        else
        {
            [comments appendFormat:@"\t@param POST %@ \n", p.paramKey];
        }
        
        [var_decalre appendFormat:@"\t%@ *p_%@;\n", type, p.paramKey];
        [property_declare appendFormat:@"@property (nonatomic, copy) %@ *p_%@;", type, p.paramKey];
        [syn_declare appendFormat:@"@synthesize p_%@ = _p_%@;", p.paramKey, p.paramKey];
        [dealloc_declare appendFormat:@"\t[_p_%@ release];\n", p.paramKey];
    }
    
    [comments appendString:@"*/"];
    [var_decalre appendString:@"}\n"];
    [dealloc_declare appendString:@"\n\t[super dealloc];\n}"];
         
    NSString *return_ms = [NSString stringWithFormat:@"\treturn [NSDictionary dictionaryWithObjectsAndKeys:getParams, @\"getParams\", postDatas, @\"postDatas\", nil];"];
    NSString *local_define = @"\n\tNSMutableDictionary *getParams = [NSMutableDictionary dictionaryWithCapacity:5];\n\tNSMutableDictionary *postDatas = [NSMutableDictionary dictionaryWithCapacity:5];\n";
    [all appendFormat:@"%@\n%@\n{%@\n%@\n\t%@\n\n%@\n}",comments, method_name, local_define, get_assigns, post_assigns, return_ms];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:all, @"implement", method_name, @"declare", comments, @"comment", var_decalre, @"var_decalre", property_declare, @"property_declare", syn_declare, @"syn_declare", dealloc_declare, @"dealloc_declare", nil];
}

+(BOOL)javaExportApis:(NSArray*)apis inProject:(PAProject*)project toFolderPath:(NSString *)folderPath
{
    NSString *srcTemplatePath = [[NSBundle mainBundle] pathForResource:@"java_ApiWrapper_Template" ofType:@"strings"];
    NSMutableString *srcTemplateString = [NSMutableString stringWithContentsOfFile:srcTemplatePath encoding:NSUnicodeStringEncoding error:nil];
    
    NSString *srcTemplatePathCaller = [[NSBundle mainBundle] pathForResource:@"java_ApiCaller_Template" ofType:@"strings"];
    NSMutableString *srcTemplateStringCaller = [NSMutableString stringWithContentsOfFile:srcTemplatePathCaller encoding:NSUnicodeStringEncoding error:nil];
    
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSString *api_path = [NSString stringWithFormat:@"%@/%@/JAVA/com/dtapi/api", folderPath, project.name];
    [filemanager createDirectoryAtPath:api_path withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *exportSrcPath = [NSString stringWithFormat:@"%@/DTApiWrapper.java", api_path];
    NSString *exportSrcPathCaller = [NSString stringWithFormat:@"%@/DTApiCaller.java", api_path];
    
    //Project Name
    [srcTemplateString replaceOccurrencesOfString:@"$Project.name" withString:project.name options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];

    [srcTemplateStringCaller replaceOccurrencesOfString:@"$Project.name" withString:project.name options:NSLiteralSearch range:NSMakeRange(0, srcTemplateStringCaller.length)];
    
    //date
    [srcTemplateString replaceOccurrencesOfString:@"$date" withString:[DTUtil dateStringSinceDate:[NSDate date] Format:@"yy-MM-dd"] options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];

    [srcTemplateStringCaller replaceOccurrencesOfString:@"$date" withString:[DTUtil dateStringSinceDate:[NSDate date] Format:@"yy-MM-dd"] options:NSLiteralSearch range:NSMakeRange(0, srcTemplateStringCaller.length)];
    
    NSMutableString *implement_ms = [NSMutableString stringWithCapacity:1000];
    NSMutableString *implement_ms_caller = [NSMutableString stringWithCapacity:1000];
    NSMutableString *demo_run_body = [NSMutableString stringWithCapacity:1000];
    NSMutableArray *demo_run_parts = [NSMutableArray arrayWithCapacity:10];
    
    //common params, add to wrapper
    NSDictionary *commonParams = [self javaCommonParamsForProject:project];
    NSString *common_all = [commonParams objectForKey:@"all"];
    
    [demo_run_body appendString:@"public HttpResponse demoRun(String apiName, String groupName) throws UnsupportedEncodingException{\n"];
    
    [implement_ms appendFormat:@"%@\n", common_all];
    
    NSMutableString *macros = [NSMutableString stringWithCapacity:200];
    [macros appendFormat:@"\tpublic static final String kProjectBaseUrl = \"%@\";\n\n", project.baseUrl];
    
    for (int i=0; i<apis.count; i++)
    {
        PAApi *a = [apis objectAtIndex:i];
        if (a.selectedParamGroup.getParams.count == 0 &&
            a.selectedParamGroup.postDatas.count == 0) {
            continue ;
        }
        
        //macro
        [macros appendFormat:@"\tpublic static final String kRequest_%@ = \"%@\";\n", a.macroName, a.name];
        
        //wrapper 
        NSDictionary *wrapper = [PAExportEngine javaWrapperMethodForApi:a];
        NSString *implement = [wrapper objectForKey:@"implement"];
        [implement_ms appendFormat:@"%@\n", implement];
        
        //caller
        NSDictionary *caller = [PAExportEngine javaCallerMethodForApi:a];
        
        NSString *caller_all = [caller objectForKey:@"implement"];
        [implement_ms_caller appendFormat:@"%@\n\n", caller_all];
        
        //demo
        NSArray *demo_calls = [caller objectForKey:@"demo_calls"];
        
        [demo_run_parts addObjectsFromArray:demo_calls];
    }
    
    [demo_run_body appendString:@"\n\t//Setting common params, you may do this some where else\n"];
    
    for (int i=0; i<project.commonGetParams.count; i++)
    {
        PAParam *p = [project.commonGetParams objectAtIndex:i];
        [demo_run_body appendFormat:@"\n\tdtApiWrapper.set%@(\"%@\");", [PAExportEngine upperFirstLetter:p.paramKey], p.paramValue];
    }
    
    for (int i=0; i<project.commonPostDatas.count; i++)
    {
        PAParam *p = [project.commonPostDatas objectAtIndex:i];
        [demo_run_body appendFormat:@"\n\tdtApiWrapper.setP_%@(\"%@\");", p.paramKey, p.paramValue];
    }
    
    [demo_run_body appendString:@"\n\n"];
    
    for (int i=0; i<demo_run_parts.count; i++)
    {
        [demo_run_body appendString:@"\t"];
        
        if (i != 0) {
            [demo_run_body appendString:@"else "];
        }
        
        [demo_run_body appendString:[demo_run_parts objectAtIndex:i]];
        [demo_run_body appendString:@"\n"];
    }
    
    [demo_run_body appendString:@"\treturn null;\n}"];
    
//wrapper
    //implements
    [srcTemplateString replaceOccurrencesOfString:@"$Api.implementations" withString:implement_ms options:NSLiteralSearch range:NSMakeRange(0, srcTemplateString.length)];
    
    [srcTemplateString writeToFile:exportSrcPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
//caller
    //implements
    [srcTemplateStringCaller replaceOccurrencesOfString:@"$Api.implementations" withString:implement_ms_caller options:NSLiteralSearch range:NSMakeRange(0, srcTemplateStringCaller.length)];
    [srcTemplateStringCaller replaceOccurrencesOfString:@"$Api.macros" withString:macros options:NSLiteralSearch range:NSMakeRange(0, srcTemplateStringCaller.length)];
    //demo_method
    [srcTemplateStringCaller replaceOccurrencesOfString:@"$Api.run_demo_method" withString:demo_run_body options:NSLiteralSearch range:NSMakeRange(0, srcTemplateStringCaller.length)];
    
    [srcTemplateStringCaller writeToFile:exportSrcPathCaller atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return YES;
}

//wrapper
+(NSDictionary*)javaWrapperMethodForApi:(PAApi*)api
{
    NSMutableString *all = [NSMutableString stringWithCapacity:200];
    NSMutableString *method_name = [NSMutableString stringWithCapacity:200];
    NSMutableString *get_assigns = [NSMutableString stringWithCapacity:500];
    NSMutableString *post_assigns = [NSMutableString stringWithCapacity:500];
    NSMutableString *comments = [NSMutableString stringWithCapacity:500];
    
    [comments appendFormat:@"/*\n\tApi:%@, %@\n", api.name, api.comment];
    
    [method_name appendFormat:@"public HashMap<String, Object> %@(",api.exportPrefix];
    BOOL firstParam = YES;
    
    for (int i=0; i<api.selectedParamGroup.getParams.count; i++)
    {
        PAParam *p = [api.selectedParamGroup.getParams objectAtIndex:i];
        NSString *type = [PAExportEngine exportTypeNameForParamType:p.paramType withTemplate:kPATemplateBeanJAVA];
        
        if ([api.project paramExists:p isPost:NO])
        {
            continue ;
        }
        
        if (firstParam)
        {
            [method_name appendFormat:@"%@ %@", type, p.paramKey];
            firstParam = NO;
        }
        else
        {
            [method_name appendFormat:@", %@ %@", type, p.paramKey];
        }
        
        [get_assigns appendFormat:@"\n\tif (%@ != null) getParams.add(new BasicNameValuePair(\"%@\", %@));", p.paramKey, p.paramKey, p.paramKey];
        
        if (p.comment)
        {
            [comments appendFormat:@"\t@param GET  %@ %@\n", p.paramKey, p.comment];
        }
        else
        {
            [comments appendFormat:@"\t@param GET  %@ \n", p.paramKey];
        }
    }
    
    for (int i=0; i<api.selectedParamGroup.postDatas.count; i++)
    {
        PAParam *p = [api.selectedParamGroup.postDatas objectAtIndex:i];
        NSString *type = [PAExportEngine exportTypeNameForParamType:p.paramType withTemplate:kPATemplateBeanJAVA];
        if ([api.project paramExists:p isPost:YES])
        {
            continue ;
        }
        
        if (firstParam)
        {
            [method_name appendFormat:@"%@ p_%@", type, p.paramKey];
            firstParam = NO;
        }
        else
        {
            [method_name appendFormat:@", %@ p_%@", type, p.paramKey];
        }
        
        if ([p.paramType isEqualToString:PAPARAM_TYPE_FILE])
        {
            [post_assigns appendFormat:@"\n\tif (p_%@ != null) postEntity.addPart(\"%@\", new FileBody(p_%@));", p.paramKey, p.paramKey, p.paramKey];
        }
        else
        {
            [post_assigns appendFormat:@"\n\tif (p_%@ != null) postEntity.addPart(\"%@\", new StringBody(p_%@, Charset.forName(HTTP.UTF_8)));", p.paramKey, p.paramKey, p.paramKey];
        }
        
        if (p.comment)
        {
            [comments appendFormat:@"\t@param POST %@ %@\n", p.paramKey, p.comment];
        }
        else
        {
            [comments appendFormat:@"\t@param POST %@ \n", p.paramKey];
        }
    }
    
    [comments appendString:@"*/"];
    [method_name appendString:@")"];
    
    NSString *return_ms = [NSString stringWithFormat:@"\treturn this.wrapCommonParamsWithParams(getParams, postEntity);"];
    NSString *local_define = @"\n\t\tArrayList<BasicNameValuePair> getParams = new ArrayList<BasicNameValuePair>();\n\t\tMultipartEntity postEntity = new MultipartEntity();\n";
    [all appendFormat:@"%@\n%@  throws UnsupportedEncodingException{\n%@\n%@\n\t%@\n\n%@\n}",comments, method_name, local_define, get_assigns, post_assigns, return_ms];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:all, @"implement", method_name, @"declare", comments, @"comment", nil];
}

+(NSDictionary*)javaCallerMethodForApi:(PAApi*)api
{
    NSMutableString *all = [NSMutableString stringWithCapacity:200];
    NSMutableString *method_name = [NSMutableString stringWithCapacity:200];
    NSMutableString *wrapper_def = [NSMutableString stringWithCapacity:200];
    NSMutableString *comments = [NSMutableString stringWithCapacity:500];
    
    NSMutableArray *demo_calls = [NSMutableArray arrayWithCapacity:10];
    NSMutableString *call_api_template = [NSMutableString stringWithCapacity:100];
    NSMutableString *call_body = [NSMutableString stringWithCapacity:100];
    
    [comments appendFormat:@"/*\n\tApi:%@, %@\n", api.name, api.comment];
    [method_name appendFormat:@"public HttpResponse %@(",api.exportPrefix];
    
    if ([api.url isEqualToString:@"${PROJECT_BASEURL}"]) {
        [call_body appendFormat:@"this.%@(", api.exportPrefix];
    }
    else
    {
        [call_body appendFormat:@"this.%@(", api.exportPrefix];
    }
    
    
    [wrapper_def appendFormat:@"HashMap<String, Object> wrapper = dtApiWrapper.%@(", api.exportPrefix];
    
    [call_api_template appendFormat:@"if (apiName.equals(\"%@\") && groupName.equals($$Api.groupName)) {\n\t\treturn $$Api.callerbody;\n\t}", api.name];
    
    BOOL firstParam = YES;
    
    for (int i=0; i<api.selectedParamGroup.getParams.count; i++)
    {
        PAParam *p = [api.selectedParamGroup.getParams objectAtIndex:i];
        NSString *type = [PAExportEngine exportTypeNameForParamType:p.paramType withTemplate:kPATemplateBeanJAVA];
        
        if ([api.project paramExists:p isPost:NO])
        {
            continue ;
        }
        
        if (firstParam)
        {
            [method_name appendFormat:@"%@ %@", type, p.paramKey];
            [wrapper_def appendFormat:@"%@", p.paramKey];
            [call_body appendFormat:@"$$%@", p.paramKey];
            firstParam = NO;
        }
        else
        {
            [method_name appendFormat:@", %@ %@", type, p.paramKey];
            [wrapper_def appendFormat:@", %@", p.paramKey];
            [call_body appendFormat:@", $$%@", p.paramKey];
        }
        
        if (p.comment)
        {
            [comments appendFormat:@"\t@param GET  %@ %@\n", p.paramKey, p.comment];
        }
        else
        {
            [comments appendFormat:@"\t@param GET  %@ \n", p.paramKey];
        }
        
    }
    
    for (int i=0; i<api.selectedParamGroup.postDatas.count; i++)
    {
        PAParam *p = [api.selectedParamGroup.postDatas objectAtIndex:i];
        NSString *type = [PAExportEngine exportTypeNameForParamType:p.paramType withTemplate:kPATemplateBeanJAVA];
        
        if ([api.project paramExists:p isPost:YES])
        {
            continue ;
        }
        
        if (firstParam)
        {
            [method_name appendFormat:@"%@ p_%@", type, p.paramKey];
            [wrapper_def appendFormat:@"p_%@", p.paramKey];
            [call_body appendFormat:@"$$p_%@", p.paramKey];
            firstParam = NO;
        }
        else
        {
            [method_name appendFormat:@", %@ p_%@", type, p.paramKey];
            [wrapper_def appendFormat:@", p_%@", p.paramKey];
            [call_body appendFormat:@", $$p_%@", p.paramKey];
        }
        
        if (p.comment)
        {
            [comments appendFormat:@"\t@param POST %@ %@\n", p.paramKey, p.comment];
        }
        else
        {
            [comments appendFormat:@"\t@param POST %@ \n", p.paramKey];
        }
    }
    [comments appendString:@"*/"];
    [call_body appendString:@")"];
//    [call_body appendString:@"delegate:delegate]"];
    
    for (int i=0; i<api.paramGroups.count; i++)
    {
        NSMutableString *tmp_call = [NSMutableString stringWithString:call_api_template];
        NSMutableString *tmp_body = [NSMutableString stringWithString:call_body];
        
        PAParamGroup *pg = [api.paramGroups objectAtIndex:i];
        for (int j=0; j<pg.getParams.count; j++)
        {
            PAParam *param = [pg.getParams objectAtIndex:j];
            NSString *sign = [NSString stringWithFormat:@"$$%@", param.paramKey];
            NSString *pv = [param.paramValue stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            NSString *replace_paramName = [NSString stringWithFormat:@"\"%@\"", pv];
            [tmp_body replaceOccurrencesOfString:sign withString:replace_paramName options:NSLiteralSearch range:NSMakeRange(0, tmp_body.length)];
        }
        
        for (int j=0; j<pg.postDatas.count; j++)
        {
            PAParam *param = [pg.postDatas objectAtIndex:j];
            NSString *sign = [NSString stringWithFormat:@"$$p_%@", param.paramKey];
            
            if ([param.paramType isEqualToString:PAPARAM_TYPE_FILE])
            {
                NSString *replace_paramValue = [NSString stringWithFormat:@"new File(\"%@\")", param.filename];
                [tmp_body replaceOccurrencesOfString:sign withString:replace_paramValue options:NSLiteralSearch range:NSMakeRange(0, tmp_body.length)];
            }
            else
            {
                NSString *pv = [param.paramValue stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
                NSString *replace_paramName = [NSString stringWithFormat:@"\"%@\"", pv];
                [tmp_body replaceOccurrencesOfString:sign withString:replace_paramName options:NSLiteralSearch range:NSMakeRange(0, tmp_body.length)];
            }
        }
        
        NSString *replace_groupName = [NSString stringWithFormat:@"\"%@\"", pg.name];
        
        [tmp_call replaceOccurrencesOfString:@"$$Api.groupName" withString:replace_groupName options:NSLiteralSearch range:NSMakeRange(0, tmp_call.length)];
        [tmp_call replaceOccurrencesOfString:@"$$Api.callerbody" withString:tmp_body options:NSLiteralSearch range:NSMakeRange(0, tmp_call.length)];
        
        [demo_calls addObject:tmp_call];
    }
    
//    [method_name appendString:@"delegate:(id)delegate"];
    [method_name appendString:@") throws UnsupportedEncodingException"];
    
    [wrapper_def appendFormat:@");"];
    
    NSString *macro_name = [NSString stringWithFormat:@"kRequest_%@", api.macroName];
    NSString *burl = nil;
    if ([[api.url uppercaseString] isEqualToString:@"${PROJECT_BASEURL}"])
    {
        if (api.path.length == 0) {
            burl = @"kProjectBaseUrl";
        }
        else
        {
            burl = [NSString stringWithFormat:@"kProjectBaseUrl + \"%@\"", api.path];
        }
    }
    else
    {
        burl = [NSString stringWithFormat:@"\"%@%@\"", api.url, api.path];
    }
    
    NSString *method_type = @"GET";
    if (api.selectedParamGroup.postDatas.count > 0) {
        method_type = @"POST";
    }
    NSString *return_ms = [NSString stringWithFormat:@"\treturn this.callApi(%@, %@, wrapper.get(\"getParams\"), wrapper.get(\"postDatas\"), \"%@\");", macro_name, burl, method_type];
    
    [all appendFormat:@"%@\n%@\n{\n\t%@\n\n\t%@\n}",comments, method_name, wrapper_def, return_ms];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:all, @"implement", method_name, @"declare", comments, @"comment", demo_calls, @"demo_calls", nil];
}

+(NSDictionary*)javaCommonParamsForProject:(PAProject*)project
{
    NSMutableString *var_decalre = [NSMutableString stringWithCapacity:100];
    NSMutableString *comments = [NSMutableString stringWithCapacity:500];
    NSMutableString *synthesize_ms = [NSMutableString stringWithCapacity:100];
    NSMutableString *method_name = [NSMutableString stringWithCapacity:200];
    NSMutableString *get_assigns = [NSMutableString stringWithCapacity:500];
    NSMutableString *post_assigns = [NSMutableString stringWithCapacity:500];
    
    [comments appendFormat:@"/*\n\tProject Name:%@\n", project.name];
    [method_name appendFormat:@"public HashMap<String, Object> wrapCommonParamsWithParams(ArrayList<BasicNameValuePair> getParams, MultipartEntity postEntity)  throws UnsupportedEncodingException{\n\t\
     ArrayList<BasicNameValuePair> commonGetParams = new ArrayList<BasicNameValuePair>();\
     \n\n$$common_assigns\
     \n\n\tcommonGetParams.addAll(getParams);\
     \n\n\tHashMap<String, Object> commonParams = new HashMap<String, Object>();\
     \n\tcommonParams.put(\"getParams\", commonGetParams);\
     \n\tcommonParams.put(\"postEntity\", postEntity);\
     \n\n\treturn commonParams;\n}\n"];
    
//    $$common_assigns
    for (int i=0; i<project.commonGetParams.count; i++)
    {
        PAParam *p = [project.commonGetParams objectAtIndex:i];
        NSString *type = [PAExportEngine exportTypeNameForParamType:p.paramType withTemplate:kPATemplateBeanJAVA];
        
        [get_assigns appendFormat:@"\n\tif (%@ != null) commonGetParams.add(new BasicNameValuePair(\"%@\", %@));", p.paramKey, p.paramKey, p.paramKey];
        
        if (p.comment)
        {
            [comments appendFormat:@"\t@param GET  %@ %@\n", p.paramKey, p.comment];
        }
        else
        {
            [comments appendFormat:@"\t@param GET  %@ \n", p.paramKey];
        }
        
        [var_decalre appendFormat:@"\n\t%@ %@;", type, p.paramKey];
        
        //setter
        [synthesize_ms appendFormat:@"\tpublic void set%@(String %@) {\n\t\tthis.%@ = %@;\n\t}\n", [PAExportEngine upperFirstLetter:p.paramKey], p.paramKey, p.paramKey, p.paramKey];
        //getter
        [synthesize_ms appendFormat:@"\tpublic String get%@() {\n\t\t return %@;\n\t}\n", [PAExportEngine upperFirstLetter:p.paramKey], p.paramKey];
    }
    
    for (int i=0; i<project.commonPostDatas.count; i++)
    {
        PAParam *p = [project.commonPostDatas objectAtIndex:i];
        NSString *type = [PAExportEngine exportTypeNameForParamType:p.paramType withTemplate:kPATemplateBeanJAVA];
        
        if ([p.paramType isEqualToString:PAPARAM_TYPE_FILE])
        {
            [post_assigns appendFormat:@"\n\tif (p_%@ != null) postEntity.addPart(\"%@\", new FileBody(p_%@));", p.paramKey, p.paramKey, p.paramKey];
        }
        else
        {
            [post_assigns appendFormat:@"\n\tif (p_%@ != null) postEntity.addPart(\"%@\", new StringBody(p_%@, Charset.forName(HTTP.UTF_8)));", p.paramKey, p.paramKey, p.paramKey];
        }
        
        if (p.comment)
        {
            [comments appendFormat:@"\t@param POST  %@ %@\n", p.paramKey, p.comment];
        }
        else
        {
            [comments appendFormat:@"\t@param POST  %@ \n", p.paramKey];
        }
        
        [var_decalre appendFormat:@"\n\t%@ p_%@;", type, p.paramKey];
        
        //setter
        [synthesize_ms appendFormat:@"\tpublic void setP_%@(String p_%@) {\n\t\tthis.p_%@ = p_%@;\n\t}\n", p.paramKey, p.paramKey, p.paramKey, p.paramKey];
        //getter
        [synthesize_ms appendFormat:@"\tpublic String getP_%@() {\n\t\t return p_%@;\n\t}\n", p.paramKey, p.paramKey];
    }
    
    NSMutableString *tmp = [NSMutableString stringWithCapacity:100];
    [tmp appendString:get_assigns];
    [tmp appendString:post_assigns];
    
    [method_name replaceOccurrencesOfString:@"$$common_assigns" withString:tmp options:NSCaseInsensitiveSearch range:NSMakeRange(0, method_name.length)];
    
    [comments appendString:@"*/\n"];
    
    NSMutableString *all = [NSMutableString stringWithCapacity:500];
    [all appendFormat:@"%@\n%@\n%@\n%@\n", var_decalre, synthesize_ms, comments, method_name];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:all, @"all", method_name, @"implement", comments, @"comment", var_decalre, @"var_decalre", synthesize_ms, @"syn_declare", nil];
}

+(NSString*)exportTypeNameForParamType:(NSString*)paramType withTemplate:(PATemplateBean)templateName
{
    if (templateName == kPATemplateBeanIOS)
    {
        if ([paramType isEqualToString:PAPARAM_TYPE_STRING]) {
            return @"NSString";
        }
        else if ([paramType isEqualToString:PAPARAM_TYPE_NUMBER])
        {
            return @"NSString";
        }
        else if ([paramType isEqualToString:PAPARAM_TYPE_FILE])
        {
            return @"NSData";
        }
    }
    else if (templateName == kPATemplateBeanJAVA)
    {
        if ([paramType isEqualToString:PAPARAM_TYPE_STRING]) {
            return @"String";
        }
        else if ([paramType isEqualToString:PAPARAM_TYPE_NUMBER])
        {
            return @"String";
        }
        else if ([paramType isEqualToString:PAPARAM_TYPE_FILE])
        {
            return @"File";
        }
    }
    return nil;
}


+(NSArray*)arrayForJsonString:(NSString*)jsonString type:(NSString*)type
{
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
    
    id jsonObject = [jsonString JSONValue];
    
    if ([jsonObject isKindOfClass:[NSArray class]])
    {
        NSArray *array = jsonObject;
        for (int i=0; i<array.count; i++)
        {
            NSDictionary *dict = [array objectAtIndex:i];
            id obj = nil;
            
            if ([type isEqualToString:PAOBJECT_NAME_PROJECT_ARRAY])
            {
                obj = [[[PAProject alloc] initWithDict:dict] autorelease];
            }
            else if ([type isEqualToString:PAOBJECT_NAME_BEAN_ARRAY])
            {
                obj = [[[PABean alloc] initWithDict:dict] autorelease];
            }
            else if ([type isEqualToString:PAOBJECT_NAME_API_ARRAY])
            {
                obj = [[[PAApi alloc] initWithDict:dict] autorelease];
            }
            else if ([type isEqualToString:PAOBJECT_NAME_PARAM_ARRAY])
            {
                obj = [[[PAParam alloc] initWithDict:dict] autorelease];
            }
            else if ([type isEqualToString:PAOBJECT_NAME_PROPERTY_ARRAY])
            {
                obj = [[[PAProperty alloc] initWithDict:dict] autorelease];
            }
            else if ([type isEqualToString:PAOBJECT_NAME_NEW_BEAN_ARRAY])
            {
//                obj = [[[PABean alloc] initWithDict:dict] autorelease];
            }
            else if ([type isEqualToString:PAOBJECT_NAME_BEANFOLDER_ARRAY])
            {
                obj = [[[PABeanFolder alloc] initWithDict:dict] autorelease];
                [ma addObjectsFromArray:((PABeanFolder*)obj).allChildren];
                obj = nil;
            }
            else if ([type isEqualToString:PAOBJECT_NAME_APIFOLDER_ARRAY])
            {
                obj = [[[PAApiFolder alloc] initWithDict:dict] autorelease];
                [ma addObjectsFromArray:((PAApiFolder*)obj).allChildren];
                obj = nil;
            }
            else if ([type isEqualToString:PAOBJECT_NAME_APIRESULT_ARRAY])
            {
                obj = [[[PAApiResult alloc] initWithDict:dict] autorelease];
            }
            else if ([type isEqualToString:PAOBJECT_NAME_PARAMGROUP_ARRAY])
            {
                obj = [[[PAParamGroup alloc] initWithDict:dict] autorelease];
            }
            
            if (obj) {
                [ma addObject:obj];
            }
        }
    }
    else if ([jsonObject isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = jsonObject;
        id obj = nil;
        
        if ([type isEqualToString:PAOBJECT_NAME_PROJECT])
        {
            obj = [[[PAProject alloc] initWithDict:dict] autorelease];
        }
        else if ([type isEqualToString:PAOBJECT_NAME_BEAN])
        {
            obj = [[[PABean alloc] initWithDict:dict] autorelease];
        }
        else if ([type isEqualToString:PAOBJECT_NAME_API])
        {
            obj = [[[PAApi alloc] initWithDict:dict] autorelease];
        }
        else if ([type isEqualToString:PAOBJECT_NAME_PARAM])
        {
            obj = [[[PAParam alloc] initWithDict:dict] autorelease];
        }
        else if ([type isEqualToString:PAOBJECT_NAME_PROPERTY])
        {
            obj = [[[PAProperty alloc] initWithDict:dict] autorelease];
        }
        else if ([type isEqualToString:PAOBJECT_NAME_BEANFOLDER])
        {
            obj = [[[PABeanFolder alloc] initWithDict:dict] autorelease];
            [ma addObjectsFromArray:((PABeanFolder*)obj).allChildren];
            obj = nil;
        }
        else if ([type isEqualToString:PAOBJECT_NAME_APIFOLDER])
        {
            obj = [[[PAApiFolder alloc] initWithDict:dict] autorelease];
            [ma addObjectsFromArray:((PAApiFolder*)obj).allChildren];
            obj = nil;
        }
        else if ([type isEqualToString:PAOBJECT_NAME_APIRESULT])
        {
            obj = [[[PAApiResult alloc] initWithDict:dict] autorelease];
        }
        else if ([type isEqualToString:PAOBJECT_NAME_PARAMGROUP])
        {
            obj = [[[PAParamGroup alloc] initWithDict:dict] autorelease];
        }
        
        if (obj) {
            [ma addObject:obj];
        }
    }
    
    return ma;
}


+(NSString*)upperFirstLetter:(NSString*)str
{
    if (str.length == 0) {
        return @"";
    }
    
    NSString *fl = [str substringToIndex:1];
    NSMutableString *ms = [NSMutableString stringWithCapacity:10];
    [ms appendString:[fl uppercaseString]];
    
    if (str.length > 1) {
        [ms appendString:[str substringFromIndex:1]];
    }
    
    return ms;
}
@end
