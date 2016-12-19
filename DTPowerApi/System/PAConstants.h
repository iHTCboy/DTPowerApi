//
//  PAConstants.h
//  DTPowerApi
//
//  Created by leks on 12-12-27.
//  Copyright (c) 2012年 leks. All rights reserved.
//

#ifndef DTPowerApi_PAConstants_h
#define DTPowerApi_PAConstants_h

#define PAOBJECT_SOURCE_TYPE @"PAOBJECT_SOURCE_TYPE"

#define PAOBJECT_NAME_FILE      @"File"
#define PAOBJECT_NAME_PROJECT   @"Project"
#define PAOBJECT_NAME_API       @"Api"
#define PAOBJECT_NAME_PARAM     @"Param"
#define PAOBJECT_NAME_BEAN      @"Bean"
#define PAOBJECT_NAME_PROPERTY  @"Property"
#define PAOBJECT_NAME_Field     @"Field"
#define PAOBJECT_NAME_RESPONSE  @"Response"
#define PAOBJECT_NAME_APIRESULT @"ApiResult"
#define PAOBJECT_NAME_PARAMGROUP @"ParamGroup"

#define PAOBJECT_NAME_NEW_BEAN @"NewBean"
#define PAOBJECT_NAME_NEW_API @"NewApi"
#define PAOBJECT_NAME_NEW_PARAM @"NewParam"
#define PAOBJECT_NAME_NEW_PROPERTY @"NewProperty"

#define PAOBJECT_NAME_PROJECT_ARRAY @"ProjectArray"
#define PAOBJECT_NAME_BEAN_ARRAY @"BeanArray"
#define PAOBJECT_NAME_API_ARRAY @"ApiArray"
#define PAOBJECT_NAME_PARAM_ARRAY @"ParamArray"
#define PAOBJECT_NAME_PROPERTY_ARRAY @"PropertyArray"
#define PAOBJECT_NAME_NEW_BEAN_ARRAY @"NewBeanArray"
#define PAOBJECT_NAME_NEW_API_ARRAY @"NewApiArray"
#define PAOBJECT_NAME_BEANFOLDER_ARRAY @"BeanFolderArray"
#define PAOBJECT_NAME_APIFOLDER_ARRAY @"ApiFolderArray"
#define PAOBJECT_NAME_APIRESULT_ARRAY @"ApiResultArray"
#define PAOBJECT_NAME_PARAMGROUP_ARRAY @"ParamGroupArray"


#define PAOBJECT_NAME_APIFOLDER @"ApiFolder"
#define PAOBJECT_NAME_BEANFOLDER @"BeanFolder"

#define PARSE_ERROR_TIPS        @"Data parse error！"

#define PAOBJECT_DESC_PROJECT @"A Project contains two folders: Apis and Beans.The Api Base URL will be set as default http request address to an new api represented by ${PROJECT_BASEURL}.The common params will be used by all apis under this project."
#define PAOBJECT_DESC_API @"In current version, api supports http requests(Get and Post).You can create different groups of parameters.Multiple results also supported."
#define PAOBJECT_DESC_PARAM @"This is the description of Param."
#define PAOBJECT_DESC_BEAN @"A Bean represents a class in Object-Oriented programming and its properties represents member variables."
#define PAOBJECT_DESC_PROPERTY @"This is the description of Property."
#define PAOBJECT_DESC_FIELD @"This is the description of Field."
#define PAOBJECT_DESC_RESPONSE @"This is the description of Response."
#define PAOBJECT_DESC_APIFOLDER @"This is the description of ApiFolder."
#define PAOBJECT_DESC_BEANFOLDER @"This is the description of BeanFolder."

#define PANOTIFICATION_PROJECTROOT_CHANGED @"PANOTIFICATION_PROJECTROOT_CHANGED"
#define PANOTIFICATION_PROJECT_BEANS_CHANGED @"PANOTIFICATION_PROJECT_BEANS_CHANGED"
#define PANOTIFICATION_PROJECT_APIS_CHANGED @"PANOTIFICATION_PROJECT_APIS_CHANGED"
#define PANOTIFICATION_PROJECT_PARAMS_CHANGED @"PANOTIFICATION_PROJECT_PARAMS_CHANGED"

#define PANOTIFICATION_PROJECTPANEL_CHANGED @"PANOTIFICATION_PROJECTPANEL_CHANGED"
#define PANOTIFICATION_APISELECTION_CHANGED @"PANOTIFICATION_APISELECTION_CHANGED"
#define PANOTIFICATION_APIRESULT_SELECTION_CHANGED @"PANOTIFICATION_APIRESULT_SELECTION_CHANGED"

#define PANOTIFICATION_OBJECT_VALUE_CHANGED @"PANOTIFICATION_OBJECT_VALUE_CHANGED"
#define PANOTIFICATION_OBJECT_VALUE_EXISTS @"PANOTIFICATION_OBJECT_VALUE_EXISTS"
#define PANOTIFICATION_OBJECT_VALUE_EMPTY @"PANOTIFICATION_OBJECT_VALUE_EMPTY"
#define PANOTIFICATION_PROJECT_CHILDREN_CHANGED @"PANOTIFICATION_PROJECT_CHILDREN_CHANGED"
#define PANOTIFICATION_BEAN_CHILDREN_CHANGED @"PANOTIFICATION_BEAN_CHILDREN_CHANGED"
#define PANOTIFICATION_API_CHILDREN_CHANGED @"PANOTIFICATION_API_CHILDREN_CHANGED"
#define PANOTIFICATION_API_STATUS_CHANGED @"PANOTIFICATION_API_STATUS_CHANGED"
#define PANOTIFICATION_API_PARSE_FALED @"PANOTIFICATION_API_PARSE_FALED"

#define PANOTIFICATION_PROJECT_MAPPING_CHANGED @"PANOTIFICATION_PROJECT_MAPPING_CHANGED"
#define PANOTIFICATION_PROJECT_CHILDREN_NUMBER_CHANGED @"PANOTIFICATION_PROJECT_CHILDREN_NUMBER_CHANGED"

#define PAFILE_LASTSAVED_PATH_KEY @"PAFILE_LASTSAVED_PATH_KEY"
#define PAFILE_PROJECT_DATAS_KEY @"project_datas"
#define PAFILE_SETTING_KEY @"workspace_setting"


#define G_BASE_LOCALE_DIR [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

typedef enum _PATemplateBean {
    kPATemplateBeanIOS,
    kPATemplateBeanJAVA
}PATemplateBean;

#endif
