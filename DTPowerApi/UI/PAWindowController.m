//
//  PAWindowController.m
//  DTPowerApi
//
//  Created by leks on 12-12-27.
//  Copyright (c) 2012年 leks. All rights reserved.
//

#import "PAWindowController.h"
#import "PAProject.h"
#import "PAApi.h"
#import "PABean.h"
#import "ProjectDetailViewController.h"
#import "JSON.h"
#import "DTUtil.h"
#import "PAConstants.h"
#import "Global.h"
#import "PAMappingEngine.h"
#import "GTMBase64.h"
#import "ExportSettingController.h"
#import "ZipFile.h"
#import "ZipReadStream.h"
#import "ZipWriteStream.h"
#import "FileInZipInfo.h"
#import "AppDelegate.h"

@interface PAWindowController ()

@end

@implementation PAWindowController
@synthesize projectPanelController;
@synthesize projectDetailController;
@synthesize apiDetailController;
@synthesize beanDetailController;
@synthesize container;
@synthesize saveURL = _saveURL;
@synthesize dataMappingController;
@synthesize currentItem;
@synthesize selectedObjects;
@synthesize openPath;

-(void)dealloc
{
    [container release];
    [projectPanelController release];
    [projectDetailController release];
    [apiDetailController release];
    [beanDetailController release];
    [_saveURL release];
    [dataMappingController release];
    [currentItem release];
    [selectedObjects release];
    [openPath release];
    [super dealloc];
}

-(void)setSaveURL:(NSURL *)saveURL
{
    [_saveURL release];
    _saveURL = [saveURL retain];
    
    if (_saveURL) USER_DEFAULTS_SAVE(_saveURL.path, PAFILE_LASTSAVED_PATH_KEY);
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    NSDocumentController *dc = [NSDocumentController sharedDocumentController];
    
    gWindowController = self;
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    inspectorExpanded = YES;
    outlineExpanded = YES;
    logExpanded = YES;
    saving = NO;
    
    [self disableAllMenu];
    
    [self resetTitle];
    USER_DEFAULTS_REMOVE(PAFILE_LASTSAVED_PATH_KEY);
    
    self.selectedObjects = [NSMutableArray arrayWithCapacity:10];
    if (openPath) {
        self.saveURL = [NSURL URLWithString:openPath];
    }
    
    DataMappingViewController *dmc = [[DataMappingViewController alloc] initWithNibName:@"DataMappingViewController" bundle:nil];
    self.dataMappingController = dmc;
    [dmc release];
    dmc.view.frame = middle.bounds;
    
    [middle addSubview:dmc.view];
    [middle setBackgroundImage:[NSImage imageNamed:@"datamapping_bg"]];
    [self.dataMappingController.view removeFromSuperview];
    
    ProjectPanelViewController *ppc = [[ProjectPanelViewController alloc] initWithNibName:@"ProjectPanelViewController" bundle:nil];
    ppc.savedURL = self.saveURL;
    self.projectPanelController = ppc;
    [ppc release];
    ppc.view.frame = left.bounds;
    
    [left addSubview:ppc.view];
//    [left setBackgroundImage:[NSImage imageNamed:@"projectpanel_bg"]];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectSelectionChanged:) name:PANOTIFICATION_PROJECTPANEL_CHANGED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiRunFinished:) name:PAAPI_REQUEST_FINISHED_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectRootChanged:) name:PANOTIFICATION_PROJECTROOT_CHANGED object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
               selector:@selector(tableSelectionDidChangeNotification:)
                   name:NSOutlineViewSelectionDidChangeNotification
                 object:dataMappingController.jsonOutlineView];
    [[NSNotificationCenter defaultCenter] addObserver:self
               selector:@selector(tableSelectionDidChangeNotification:)
                   name:NSOutlineViewSelectionDidChangeNotification
                 object:dataMappingController.beanOutlineView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(apiStatusChanged:)
                                                 name:PANOTIFICATION_API_STATUS_CHANGED
                                               object:nil];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(autoSaveAll:) userInfo:nil repeats:YES];
    
    NSString *path = USER_DEFAULTS_GET(PAFILE_LASTSAVED_PATH_KEY);
    NSURL *pathUrl = nil;
    
    if (path) {
        pathUrl = [NSURL URLWithString:path];
    }
    
    if(pathUrl && ![self loadFile:pathUrl])
    {
        NSString *msg = [NSString stringWithFormat:@"Fail to open file %@", pathUrl.path];
        NSAlert *alert = [NSAlert alertWithMessageText:msg defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:nil];
        [alert runModal];
        USER_DEFAULTS_REMOVE(PAFILE_LASTSAVED_PATH_KEY);
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [GlobalSetting undoManager];
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (dividerIndex == 0) {
        return 200;
    }
    else if (dividerIndex == 1)
    {
        return self.window.frame.size.width - 320;
    }
    return 200;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (dividerIndex == 0) {
        return 400;
    }
    else if (dividerIndex == 1)
    {
        return self.window.frame.size.width - 320;
    }
    return 300;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
    if (view == left)
    {
        if (view.frame.size.width <= 200) {
            return NO;
        }
    }

    return YES;
}

-(void)apiRunFinished:(NSNotification*)notification
{
//    PAApi *api = notification.object;
    [self reloadMenuStatus];
}

-(void)reloadMenuStatus
{
    [startApiItem setTarget:nil];
    [startApiItem setAction:nil];
    
    [stopApiItem setTarget:nil];
    [stopApiItem setAction:nil];
    
    [startAllApiItem setTarget:nil];
    [startAllApiItem setAction:nil];
    
    if ([self.currentItem isKindOfClass:[PAApi class]])
    {
        BOOL hasRunning = NO;
        for (int i=0; i<self.selectedObjects.count; i++)
        {
            PAApi *sapi = [self.selectedObjects objectAtIndex:i];
            if (sapi.status == PAApiStatusRunning)
            {
                hasRunning = YES;
            }
        }
        
        if (hasRunning)
        {
            [stopApiItem setTarget:self];
            [stopApiItem setAction:@selector(stopApi:)];
        }
        else
        {
            [startApiItem setTarget:self];
            [startApiItem setAction:@selector(startApi:)];
        }
    }
    else if ([self.currentItem isKindOfClass:[PAApiFolder class]] ||
             [self.currentItem isKindOfClass:[PAProject class]])
    {
        PAApiFolder *folder = nil;
        
        if ([self.currentItem isKindOfClass:[PAApiFolder class]]) {
            folder = self.currentItem;
        }
        else if ([self.currentItem isKindOfClass:[PAProject class]])
        {
            folder = [(PAProject*)self.currentItem apis];
        }
        
        BOOL hasRunning = NO;
        for (int i=0; i<folder.allChildren.count; i++)
        {
            PAApi *sapi = [folder.allChildren objectAtIndex:i];
            if (sapi.status == PAApiStatusRunning)
            {
                hasRunning = YES;
            }
        }
        
        if (hasRunning)
        {
            [stopApiItem setTarget:self];
            [stopApiItem setAction:@selector(stopApi:)];
        }
        else
        {
            [startAllApiItem setTarget:self];
            [startAllApiItem setAction:@selector(startAllApi:)];
        }
    }
}

-(void)reloadExportMenu
{
    [exportItem setTarget:self];
    [exportItem setAction:@selector(exportAction:)];
}

-(void)disableMappingMenus
{
//    [self.apiDetailController reloadApi:nil];
    
    [addMappingItem setTarget:nil];
    [addMappingItem setAction:nil];
    
    [removePropertyItem setTarget:nil];
    [removePropertyItem setAction:nil];
    
    [createObjectItem setTarget:nil];
    [createObjectItem setAction:nil];
    
    [smartItem setTarget:nil];
    [smartItem setAction:nil];
}

-(void)apiStatusChanged:(NSNotification*)notification
{
    [self reloadMenuStatus];
}

-(void)objectSelectionChanged:(NSNotification*)notification
{
    NSArray *objs = notification.object;
    if (!objs || objs.count == 0) {
        
        return ;
    }
    id item = [objs lastObject];
    self.currentItem = [objs lastObject];
    [self.selectedObjects setArray:objs];
    
    [self reloadMenuStatus];
    
    [exportItem setTarget:self];
    [exportItem setAction:@selector(exportAction:)];
    
    [self.projectDetailController.view removeFromSuperview];
    [self.apiDetailController.view removeFromSuperview];
    [self.beanDetailController.view removeFromSuperview];
    [self.dataMappingController.view removeFromSuperview];
    
    NSUndoManager *undo = [GlobalSetting undoManager];
    if (self.projectDetailController.project) {
//        [undo removeAllActionsWithTarget:self.projectDetailController.project];
    }
    if (self.apiDetailController.api) {
//        [undo removeAllActionsWithTarget:self.apiDetailController.api];
    }
    
    if (self.beanDetailController.bean) {
//        [undo removeAllActionsWithTarget:self.beanDetailController.bean];
    }
//
//
//    [undo removeAllActionsWithTarget:self.projectDetailController.project];
    
//    self.projectDetailController = nil;
//    self.apiDetailController = nil;
//    self.beanDetailController = nil;
//    self.dataMappingController = nil;
    
    if ([item isKindOfClass:[PAProject class]])
    {
        if (!self.projectDetailController) {
            self.projectDetailController = [[[ProjectDetailViewController alloc] initWithNibName:@"ProjectDetailViewController" bundle:nil] autorelease];
        }
        
        
//        self.projectDetailController.project = item;
        
        NSRect r = [inspector bounds];
        projectDetailController.view.frame = r;
        
        [inspector addSubview:self.projectDetailController.view];
        [self.projectDetailController reloadProject:item];
        
    }
    else if ([item isKindOfClass:[PAApi class]])
    {
        if (!self.apiDetailController) {
            self.apiDetailController = [[[ApiDetailViewController alloc] initWithNibName:@"ApiDetailViewController" bundle:nil] autorelease];
        }
        
        apiDetailController.view.frame = [inspector bounds];
        [inspector addSubview:self.apiDetailController.view];
        
        [self.apiDetailController reloadApi:item];
        
        if (!self.dataMappingController) {
            DataMappingViewController *dmc = [[DataMappingViewController alloc] initWithNibName:@"DataMappingViewController" bundle:nil];
            self.dataMappingController = dmc;
            [dmc release];
        }
        
        if (self.dataMappingController) {
            self.dataMappingController.api = item;
        }
        
        self.dataMappingController.view.frame = middle.frame;
        [middle addSubview:self.dataMappingController.view];
    }
    else if ([item isKindOfClass:[PABean class]])
    {
        if (!self.beanDetailController) {
            self.beanDetailController = [[[BeanDetailViewController alloc] initWithNibName:@"BeanDetailViewController" bundle:nil] autorelease];
        }
        
        beanDetailController.view.frame = [inspector bounds];
        [inspector addSubview:self.beanDetailController.view];
        [self.beanDetailController reloadBean:item];
        [beanDetailController reloadFieldItems];
        
    }
    else
    {
        
    }
    
    if (![item isKindOfClass:[PAApi class]])
    {
        [addMappingItem setTarget:nil];
        [addMappingItem setAction:nil];
        
        [removePropertyItem setTarget:nil];
        [removePropertyItem setAction:nil];
        
        [createObjectItem setTarget:nil];
        [createObjectItem setAction:nil];
        
        [smartItem setTarget:nil];
        [smartItem setAction:nil];
    }
    
    [inspector addSubview:rightSepline];
    [left addSubview:leftSepline];
}

-(void)projectRootChanged:(NSNotification*)notification
{
    if (projectPanelController.allProjects.count == 1 ) {
        [self disableAllMenu];
        
        [self.projectDetailController.view removeFromSuperview];
        [self.apiDetailController.view removeFromSuperview];
        [self.beanDetailController.view removeFromSuperview];
        [self.dataMappingController.view removeFromSuperview];
    }
}

-(void)disableAllMenu
{
    [addMappingItem setTarget:nil];
    [addMappingItem setAction:nil];
    
    [removePropertyItem setTarget:nil];
    [removePropertyItem setAction:nil];
    
    [createObjectItem setTarget:nil];
    [createObjectItem setAction:nil];
    
    [smartItem setTarget:nil];
    [smartItem setAction:nil];
    
    [startApiItem setTarget:nil];
    [startApiItem setAction:nil];
    
    [stopApiItem setTarget:nil];
    [stopApiItem setAction:nil];
    
    [startAllApiItem setTarget:nil];
    [startAllApiItem setAction:nil];
    
    [exportItem setTarget:nil];
    [exportItem setAction:nil];
}
//-(IBAction)copy:(id)sender
//{
//    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
//    
//}
//
//-(IBAction)paste:(id)sender
//{
//    int a = 0;
//}
//
//-(IBAction)cut:(id)sender
//{
//    
//}
//
//-(IBAction)delete:(id)sender
//{
//    
//}


-(IBAction)saveDocumentAs:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = [NSArray arrayWithObject:@"dtapi"];
    NSInteger result = [savePanel runModal];
    if (result == NSFileHandlingPanelOKButton)
    {
        self.saveURL = savePanel.URL;
        [self saveDocument:nil];
        [self resetTitle];
    }
}

-(IBAction)saveDocument:(id)sender
{
    if (!self.saveURL)
    {
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        savePanel.allowedFileTypes = [NSArray arrayWithObject:@"dtapi"];
        savePanel.allowsOtherFileTypes = NO;
        NSInteger result = [savePanel runModal];
        if (result == NSFileHandlingPanelOKButton)
        {
            self.saveURL = savePanel.URL;
            [self resetTitle];
        }
    }
    
    gNeedSave = YES;
    [self autoSaveAll:nil];
}

-(void)autoSaveAll:(id)sender
{
    if (saving || !gNeedSave) {
        return ;
    }

    saving = YES;
    
    if (self.saveURL) {
        NSLog(@"auto saving...");
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:10];
        for (int i=1; i<self.projectPanelController.allProjects.count; i++)
        {
            PAProject *project = [self.projectPanelController.allProjects objectAtIndex:i];
            [ma addObject:[project toDict]];
        }
        
        NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
        [md setObject:ma forKey:PAFILE_PROJECT_DATAS_KEY];
        [md setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forKey:@"version"];
        [md setObject:PAOBJECT_NAME_FILE forKey:PAOBJECT_SOURCE_TYPE];
        [md setObject:[gGlobalSetting toDict] forKey:PAFILE_SETTING_KEY];
        
        [md writeToFile:self.saveURL.path atomically:YES];
        
        ZipFile *zipFile= [[ZipFile alloc] initWithFileName:self.saveURL.path mode:ZipFileModeCreate];
		
		ZipWriteStream *stream = [zipFile writeFileInZipWithName:@"DTApiFiles" fileDate:[NSDate dateWithTimeIntervalSinceNow:-86400.0] compressionLevel:ZipCompressionLevelFastest];
        NSString *str = [md JSONRepresentation];
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        [stream writeData:data];
		[stream finishedWriting];
        
        [zipFile close];
        [zipFile release];
        
        USER_DEFAULTS_SAVE(self.saveURL.path, PAFILE_LASTSAVED_PATH_KEY);
        gNeedSave = NO;
        NSLog(@"auto save finished...");
    }
    
    saving = NO;
}

-(IBAction)newDocument:(id)sender
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Do you really want to start a new workspace?" defaultButton:@"Yes" alternateButton:nil otherButton:@"No" informativeTextWithFormat:@""];
    NSInteger result = [alert runModal];
    
    if (result == NSAlertDefaultReturn)
    {
        if (gNeedSave && !self.saveURL)
        {
            NSAlert *alert = [NSAlert alertWithMessageText:@"You haven't save your workspace yet, save first?" defaultButton:@"Save" alternateButton:@"Don't save" otherButton:@"Cancel" informativeTextWithFormat:@""];
            NSInteger result = [alert runModal];
            
            if (result == NSAlertDefaultReturn) {
                [self saveDocument:nil];
            }
            else if (result == NSAlertAlternateReturn)
            {
            }
            else
            {
                return ;
            }
        }
    }
    else
    {
        return ;
    }
    
    while (saving) {
        ;
    }
    
    self.saveURL = nil;
    [self resetTitle];
    
    [self.projectDetailController.view removeFromSuperview];
    [self.apiDetailController.view removeFromSuperview];
    [self.beanDetailController.view removeFromSuperview];
    [self.dataMappingController.view removeFromSuperview];
    
    self.currentItem = nil;
    [self reloadMenuStatus];
    
    [exportItem setTarget:nil];
    [exportItem setAction:nil];
    
    [self.projectPanelController reloadProjects:[NSArray array]];
    NSUndoManager *undo = [GlobalSetting undoManager];
    [undo removeAllActions];
    
    
}

-(IBAction)openDocument:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = [NSArray arrayWithObject:@"dtapi"];
    NSInteger result = [openPanel runModal];
    if (result == NSFileHandlingPanelOKButton)
    {
        if(openPanel.URL && ![self loadFile:openPanel.URL])
        {
            NSString *msg = [NSString stringWithFormat:@"Fail to open file %@", self.saveURL.path];
            NSAlert *alert = [NSAlert alertWithMessageText:msg defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:nil];
            [alert runModal];
        }
    }
}

-(void)handleDocumentOpenURL:(NSURL *)url
{
    if (![self loadFile:url])
    {
        NSString *msg = [NSString stringWithFormat:@"Fail to open file %@", self.saveURL.path];
        NSAlert *alert = [NSAlert alertWithMessageText:msg defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:nil];
        [alert runModal];
    }
}

-(IBAction)copy:(id)sender
{
    NSResponder *firstResponder;
    
    firstResponder = [[self window] firstResponder];
    [self.apiDetailController copy:firstResponder];
    [self.beanDetailController copy:firstResponder];
    [self.projectDetailController copy:firstResponder];
}

-(IBAction)paste:(id)sender
{
    NSResponder *firstResponder;
    
    firstResponder = [[self window] firstResponder];
    [self.apiDetailController paste:firstResponder];
    [self.beanDetailController paste:firstResponder];
    [self.projectDetailController paste:firstResponder];
}

-(IBAction)cut:(id)sender
{
    NSResponder *firstResponder;
    
    firstResponder = [[self window] firstResponder];
    [self.apiDetailController cut:firstResponder];
    [self.beanDetailController cut:firstResponder];
    [self.projectDetailController cut:firstResponder];
}

-(IBAction)delete:(id)sender
{
    NSResponder *firstResponder;
    
    firstResponder = [[self window] firstResponder];
    [self.apiDetailController delete:firstResponder];
    [self.beanDetailController delete:firstResponder];
    [self.projectDetailController delete:firstResponder];
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
    if ([anItem tag] == 10001) {
        return [createObjectItem isEnabled];
    }
    else if ([anItem tag] == 10002) {
        return [addMappingItem isEnabled];
    }
    else if ([anItem tag] == 10003) {
        return [removePropertyItem isEnabled];
    }
    else if ([anItem tag] == 10004) {
        return [smartItem isEnabled];
    }
    else if ([anItem tag] == 20001) {
        return [startApiItem isEnabled];
    }
    else if ([anItem tag] == 20002) {
        return [startAllApiItem isEnabled];
    }
    else if ([anItem tag] == 20003) {
        return [stopApiItem isEnabled];
    }
    else if ([anItem tag] == 30001) {
        AppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
        BOOL left_segment = [segment isSelectedForSegment:0];
        if (left_segment) {
            [appDelegate reloadItem:30001 title:@"Hide Project Navigator"];
        }
        else
        {
            [appDelegate reloadItem:30001 title:@"Show Project Navigator"];
        }
    }
    else if ([anItem tag] == 30002) {
        AppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
        BOOL middle_segment = [segment isSelectedForSegment:1];
        if (middle_segment) {
            [appDelegate reloadItem:30002 title:@"Hide Log Panel"];
        }
        else
        {
            [appDelegate reloadItem:30002 title:@"Show Log Panel"];
        }
    }
    else if ([anItem tag] == 30003) {
        AppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
        BOOL right_segment = [segment isSelectedForSegment:2];
        if (right_segment) {
            [appDelegate reloadItem:30003 title:@"Hide Inspector"];
        }
        else
        {
            [appDelegate reloadItem:30003 title:@"Show Inspector"];
        }
    }
    else if ([anItem tag] == 40001) {
        return [exportItem isEnabled];
    }
    else if ([anItem tag] == 50001 ||
             [anItem tag] == 50002 ||
             [anItem tag] == 50003)
    {
        return [self.projectPanelController projectMenuValidate:[anItem tag]];
    }

    return YES;
}

-(BOOL)loadFile:(NSURL*)fileUrl
{
    BOOL ret = NO;
    if (!fileUrl) {
        return NO;
    }
    
    NSString *path = fileUrl.path;
//    if (![path hasPrefix:@"file"])
//    {
//        path = [NSString stringWithFormat:@"file:%@", path];
//    }
    ZipFile *unzipFile= [[ZipFile alloc] initWithFileName:path mode:ZipFileModeUnzip];
    [unzipFile goToFirstFileInZip];
    ZipReadStream *fileReader= [unzipFile readCurrentFileInZip];
    
    NSArray *infos= [unzipFile listFileInZipInfos];
    for (FileInZipInfo *info in infos) {
        NSString *fileInfo= [NSString stringWithFormat:@"- %@ %@ %ld (%d)", info.name, info.date, info.size, info.level];
        NSLog(@"%@", fileInfo);
    }
    
    NSMutableData *data = [NSMutableData dataWithCapacity:1024*1024*3];
    
    NSUInteger bytesRead = 0;
    do {
        NSMutableData *buffer= [[[NSMutableData alloc] initWithLength:1024*1024] autorelease];
        bytesRead = [fileReader readDataWithBuffer:buffer];
        if (bytesRead > 0) {
            [data appendData:buffer];
        }
    } while (bytesRead > 0);
    
    [fileReader finishedReading];
    
    NSString *data_str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    
    [unzipFile close];
    [unzipFile release];
    
//    NSData *b64data = [NSData dataWithContentsOfFile:fileUrl.path];
//    if (!b64data) {
//        return NO;
//    }
//    
//    NSData *data = [GTMBase64 decodeData:b64data];
//    if (!b64data) {
//        return NO;
//    }
    
    
    if (!data_str) {
        return NO;
    }
    
    NSDictionary *tmp = [data_str JSONValue];

    if (tmp)
    {
        NSDictionary *settingDict = [tmp objectForKey:PAFILE_SETTING_KEY];
        if (settingDict) {
            [gGlobalSetting reloadWithDict:settingDict];
        }
        NSMutableArray *ma = [PAProject projectsForDictionary:tmp];
        if (!ma || ma.count == 0) {
            ret = NO;
        }
        else
        {
            self.saveURL = fileUrl;
            [self resetTitle];
            ret = YES;
            [self.projectPanelController reloadProjects:ma];
        }
    }
    
    return ret;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    NSSize size = frameSize;
    if (size.width < 1000) {
        size.width = 1000;
    }
    
    if (size.height < 600)
    {
        size.height = 600;
    }
    
    return size;
}

-(BOOL)windowShouldClose:(id)sender
{
    if (gNeedSave && !self.saveURL)
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"You haven't save your workspace yet, save before quit?" defaultButton:@"Save" alternateButton:@"Don't save" otherButton:@"Cancel" informativeTextWithFormat:@""];
        NSInteger result = [alert runModal];

        if (result == NSAlertDefaultReturn)
        {
            NSSavePanel *savePanel = [NSSavePanel savePanel];
            savePanel.allowedFileTypes = [NSArray arrayWithObject:@"dtapi"];
            savePanel.allowsOtherFileTypes = NO;
            NSInteger result = [savePanel runModal];
            if (result == NSFileHandlingPanelOKButton)
            {
                self.saveURL = savePanel.URL;
                [self resetTitle];
                gNeedSave = YES;
                [self autoSaveAll:nil];
                return YES;
            }
            else
            {
                return NO;
            }
        }
        else if (result == NSAlertAlternateReturn)
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    else
    {
        gNeedSave = YES;
        [self autoSaveAll:nil];
    }
    return YES;
}

-(void)windowWillClose:(NSNotification *)notification
{
    
}

#pragma mark -
#pragma mark ***** Toolbar Actions *****

-(IBAction)startApi:(id)sender
{
    for (int i=0; i<self.selectedObjects.count; i++) {
        PAApi *api = [self.selectedObjects objectAtIndex:i];
        [api start];
    }
}

-(IBAction)startAllApi:(id)sender
{
    PAApiFolder *folder = nil;
    
    if ([self.currentItem isKindOfClass:[PAApiFolder class]]) {
        folder = self.currentItem;
    }
    else if ([self.currentItem isKindOfClass:[PAProject class]])
    {
        folder = [(PAProject*)self.currentItem apis];
    }
    
    for (int i=0; i<folder.allChildren.count; i++)
    {
        PAApi *api = [folder.allChildren objectAtIndex:i];
        if (api.status == PAApiStatusRunning) {
            continue;
        }
        
        [api start];
    }
}

-(IBAction)stopApi:(id)sender
{
    for (int i=0; i<self.selectedObjects.count; i++) {
        PAApi *api = [self.selectedObjects objectAtIndex:i];
        [api cancel];
    }
}

-(IBAction)mappingFieldAction:(id)sender
{
    [self.dataMappingController mappingField];
}

-(IBAction)removePropertyAction:(id)sender
{
    [self.dataMappingController removeProperty];
}

-(IBAction)createBeanObject:(id)sender
{
    [self.dataMappingController createBeanObject];
}

-(IBAction)smartAction:(id)sender
{
    [self.dataMappingController smartAction];
}

//-(IBAction)exportBeanAction:(id)sender
//{
//    [self.projectPanelController exportBeanAction];
//}
//
//-(IBAction)exportAllBeansAction:(id)sender
//{
//    [self.projectPanelController exportAllBeansAction];
//}

-(IBAction)exportAction:(id)sender
{
//    [self.projectPanelController exportBeanAction];
    PAProject *selectedProject = nil;
    
    NSMutableArray *currentBeans = [NSMutableArray arrayWithCapacity:10];
    NSMutableArray *currentApis = [NSMutableArray arrayWithCapacity:10];
    
    if ([self.currentItem isKindOfClass:[PAProject class]]) {
        //all
        selectedProject = self.currentItem;
        [currentBeans addObjectsFromArray:selectedProject.beans.allChildren];
        [currentApis addObjectsFromArray:selectedProject.apis.allChildren];
    }
    else if ([self.currentItem isKindOfClass:[PAApiFolder class]]) {
        //all api
        selectedProject = [(PAApiFolder*)self.currentItem project];
        [currentApis addObjectsFromArray:selectedProject.apis.allChildren];
    }
    else if ([self.currentItem isKindOfClass:[PABeanFolder class]]) {
        //all bean
        selectedProject = [(PABeanFolder*)self.currentItem project];
        [currentBeans addObjectsFromArray:selectedProject.beans.allChildren];
    }
    else if ([self.currentItem isKindOfClass:[PAApi class]]) {
        //selection of api
        selectedProject = [(PAApi*)self.currentItem project];
        [self.projectPanelController.selection enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            id item = [self.projectPanelController.projectPanel itemAtRow:idx];
            [currentApis addObject:item];
        }];
    }
    else if ([self.currentItem isKindOfClass:[PABean class]]) {
        //selection of bean
        selectedProject = [(PABean*)self.currentItem project];
        [self.projectPanelController.selection enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            id item = [self.projectPanelController.projectPanel itemAtRow:idx];
            [currentBeans addObject:item];
        }];
    }
    NSMutableArray *pjs = [NSMutableArray arrayWithArray:self.projectPanelController.allProjects];
    [pjs removeObjectAtIndex:0];
    
    
    ExportSettingController *export = [[ExportSettingController alloc] initWithWindowNibName:@"ExportSettingController"];
    export.currentApis = currentApis;
    export.currentBeans = currentBeans;
    export.projects = pjs;
    export.selectedProject = selectedProject;
    [[NSApplication sharedApplication] runModalForWindow:export.window];
    [export release];
}

-(IBAction)menuAddProject:(id)sender
{
    [self.projectPanelController addProjectFromMenu];
}

-(IBAction)menuAddApi:(id)sender
{
    [self.projectPanelController addApiFromTopMenu];
}

-(IBAction)menuAddBean:(id)sender
{
    [self.projectPanelController addBeanFromTopMenu];
}

-(void)expandInspectorAction:(BOOL)selected
{
    if (selected == inspectorExpanded) {
        return ;
    }
    
    if (!selected) {
        middle.frame = right.bounds;
        CGRect r = inspector.frame;
        r.size.width = 0;
        r.origin.x = right.frame.size.width;
        inspector.frame = r;
    }
    else
    {
        CGRect r = inspector.frame;
        r.size.width = 320;
        r.origin.x = right.frame.size.width - 320;
        inspector.frame = r;
        
        r = middle.frame;
        r.size.width = right.frame.size.width - 320;
        middle.frame = r;
    }
    
    inspectorExpanded = selected;
}

-(void)expandNavigatorAction:(BOOL)selected
{
    if (outlineExpanded == selected) {
        return ;
    }
    
    if (selected) {
        [container setPosition:200 ofDividerAtIndex:0];
        NSRect r = container.frame;
        r.size.width = self.window.frame.size.width;
        container.frame = r;
    }
    else
    {
        [container setPosition:0 ofDividerAtIndex:0];
        NSRect r = container.frame;
        r.size.width = self.window.frame.size.width;
        container.frame = r;
    }
    
    outlineExpanded = selected;
}

-(void)expandLogPannel:(BOOL)selected
{
    if (logExpanded == selected) {
        return ;
    }
    
    NSSplitView *dsv = (NSSplitView*)self.dataMappingController.view;
    if (selected) {
        [dsv setPosition:dsv.frame.size.height - 200 ofDividerAtIndex:0];
    }
    else
    {
        [dsv setPosition:dsv.frame.size.height - 80 ofDividerAtIndex:0];
    }
    
    logExpanded = selected;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    return YES;
}

-(IBAction)expandPanelActions:(id)sender
{
    BOOL left_segment = [segment isSelectedForSegment:0];
    BOOL middle_segment = [segment isSelectedForSegment:1];
    BOOL right_segment = [segment isSelectedForSegment:2];
    
    [self expandNavigatorAction:left_segment];
    [self expandLogPannel:middle_segment];
    [self expandInspectorAction:right_segment];
}

-(IBAction)menuExpandNaivigator:(id)sender
{
    BOOL left_segment = [segment isSelectedForSegment:0];
    [segment setSelected:!left_segment forSegment:0];
    [self expandPanelActions:nil];
}

-(IBAction)menuExpandLog:(id)sender
{
    BOOL middle_segment = [segment isSelectedForSegment:1];
    [segment setSelected:!middle_segment forSegment:1];
    [self expandPanelActions:nil];
}

-(IBAction)menuExpandInspector:(id)sender
{
    BOOL right_segment = [segment isSelectedForSegment:2];
    [segment setSelected:!right_segment forSegment:2];
    [self expandPanelActions:nil];
}

#pragma mark -
#pragma mark ***** Toolbar Delegate *****
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return @[];
    return @[@"StartApi", @"Mapping", @"Remove"];
}

- (void)tableSelectionDidChangeNotification:(NSNotification *) notification
{
    if (notification.object == self.dataMappingController.jsonOutlineView ||
        notification.object == self.dataMappingController.beanOutlineView)
    {
        
        [self reloadMappingMenuStatus];
        
//        if ([selectedJsonField.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
//        {
//            [createObjectItem setTarget:self];
//            [createObjectItem setAction:@selector(createBeanObject:)];
//        }
//        
//        [smartItem setTarget:self];
//        [smartItem setAction:@selector(smartAction:)];
    }
}

-(void)reloadMappingMenuStatus
{
    NSOutlineView *jsOV = self.dataMappingController.jsonOutlineView;
    NSOutlineView *bOV = self.dataMappingController.beanOutlineView;
    
    PAField *selectedJsonField = [jsOV itemAtRow:jsOV.selectedRow];
    PAField *selectedBeanField = [bOV itemAtRow:bOV.selectedRow];
    
    
    [addMappingItem setTarget:nil];
    [addMappingItem setAction:nil];
    
    [removePropertyItem setTarget:nil];
    [removePropertyItem setAction:nil];
    
    [createObjectItem setTarget:nil];
    [createObjectItem setAction:nil];
    
    [smartItem setTarget:nil];
    [smartItem setAction:nil];
    
    if (!selectedJsonField || !selectedBeanField) {
        return ;
    }
    
    if ([PAMappingEngine canMapFromJsonField:selectedJsonField toBeanField:selectedBeanField inProject:apiDetailController.api.project])
    {
        [addMappingItem setTarget:self];
        [addMappingItem setAction:@selector(mappingFieldAction:)];
    }
    
    if ([PAMappingEngine canSmartMapFromJsonField:selectedJsonField toBeanField:selectedBeanField inProject:apiDetailController.api.project])
    {
        [smartItem setTarget:self];
        [smartItem setAction:@selector(smartAction:)];
    }
    
    if ([PAMappingEngine canCreateFromJsonField:selectedJsonField toBeanField:selectedBeanField inProject:apiDetailController.api.project])
    {
        [createObjectItem setTarget:self];
        [createObjectItem setAction:@selector(createBeanObject:)];
    }
    
    if ([PAMappingEngine canDeleteMapFromBeanField:selectedBeanField inProject:apiDetailController.api.project])
    {
        [removePropertyItem setTarget:self];
        [removePropertyItem setAction:@selector(removePropertyAction:)];
    }
}

-(BOOL)openFile:(NSString*)filepath
{
    if (gNeedSave && !self.saveURL)
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"You haven't save your workspace yet, save now?" defaultButton:@"Save" alternateButton:@"Don't save" otherButton:@"Cancel" informativeTextWithFormat:@""];
        NSInteger result = [alert runModal];
        
        if (result == NSAlertDefaultReturn) {
            [self saveDocument:nil];
        }
        else if (result == NSAlertAlternateReturn)
        {
            
        }
        else
        {
            return NO;
        }
    }
    else
    {
        gNeedSave = YES;
        [self autoSaveAll:nil];
    }
    
    NSURL *fileUrl = [NSURL URLWithString:filepath];
    if(![self loadFile:fileUrl])
    {
        NSString *msg = [NSString stringWithFormat:@"Fail to open file %@", filepath];
        NSAlert *alert = [NSAlert alertWithMessageText:msg defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:nil];
        [alert runModal];
    }

    return YES;
}

-(void)resetTitle
{
    if (self.saveURL.path.length > 0) {
        self.window.title = [NSString stringWithFormat:@"Debug The Api (%@)", self.saveURL.path];
        [self addRecentFile:self.saveURL.path];
    }
    else
    {
        self.window.title = @"Debug The Api (Untitled)";
    }
}

-(IBAction)showHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.dtapi.com/userguide"]];
}

-(IBAction)showWebsite:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.dtapi.com"]];
}

-(void)addRecentFile:(NSString*)recentFilePath
{
    NSString *fpath = [NSString stringWithFormat:@"file:%@", recentFilePath];
    NSDocumentController *dc = [NSDocumentController sharedDocumentController];
    [dc noteNewRecentDocumentURL:[NSURL URLWithString:fpath]];
    return ;
}

@end
