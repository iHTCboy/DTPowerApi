//
//  ParamEditController.m
//  DTPowerApi
//
//  Created by leks on 13-1-17.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "ParamEditController.h"
#import "Global.h"
#import "PAParamGroup.h"
#import "PAProject.h"

@interface ParamEditController ()

@end

@implementation ParamEditController
@synthesize param;
@synthesize pEditDelegate;
@synthesize pUndoManager;
@synthesize projectMode;
@synthesize project;

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [param release];
    [pUndoManager removeAllActions];
    [pUndoManager release];
    [project release];
    [super dealloc];
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
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    if ([self.param.paramType isEqualToString:PAPARAM_TYPE_STRING])
    {
        [valueView setEditable:YES];
        [browserBtn setEnabled:NO];
    }
    else if ([self.param.paramType isEqualToString:PAPARAM_TYPE_FILE])
    {
        [valueView setEditable:NO];
        [browserBtn setEnabled:YES];
    }
    
    [filepath setEditable:NO];
}

-(void)valueExistsNotification:(NSNotification*)notification
{
    NSDictionary *dict = notification.object;
    NSString *object_type = [dict objectForKey:@"object_type"];
    NSString *key = [dict objectForKey:@"key"];
    NSString *value = [dict objectForKey:@"value"];
    id object = [dict objectForKey:@"object"];
    
    if (object != self.param) {
        return;
    }
    
    if ([object_type isEqualToString:[PAParam className]])
    {
        if ([key isEqualToString:@"paramKey"])
        {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Param key already exists!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
            [alert runModal];
            keyField.stringValue = value;
        }
        else if ([key isEqualToString:@"name"])
        {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Param name already exists!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
            [alert runModal];
            nameField.stringValue = value;
        }
    }
}

-(void)reloadParam:(PAParam*)p
{
    self.param = p;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(valueExistsNotification:) name:PANOTIFICATION_OBJECT_VALUE_EXISTS object:nil];
}

- (BOOL)windowShouldClose:(id)sender
{
    if ([self.param.method isEqualToString:PAPARAM_METHOD_GET])
    {
        if (projectMode) {
            self.param.name = [PAObject object:self.param valueByValue:nameField.stringValue forKey:@"name" existsObjects:self.project.commonGetParams];
            self.param.paramKey = [PAObject object:self.param valueByValue:keyField.stringValue forKey:@"paramKey" existsObjects:self.project.commonGetParams];
        }
        else
        {
            self.param.name = [PAObject object:self.param valueByValue:nameField.stringValue forKey:@"name" existsObjects:self.param.parentGroup.getParams];
            self.param.paramKey = [PAObject object:self.param valueByValue:keyField.stringValue forKey:@"paramKey" existsObjects:self.param.parentGroup.getParams];
        }
    }
    else
    {
        if (projectMode) {
            self.param.name = [PAObject object:self.param valueByValue:nameField.stringValue forKey:@"name" existsObjects:self.project.commonPostDatas];
            self.param.paramKey = [PAObject object:self.param valueByValue:keyField.stringValue forKey:@"paramKey" existsObjects:self.project.commonPostDatas];
        }
        else
        {
            self.param.name = [PAObject object:self.param valueByValue:nameField.stringValue forKey:@"name" existsObjects:self.param.parentGroup.postDatas];
            self.param.paramKey = [PAObject object:self.param valueByValue:keyField.stringValue forKey:@"paramKey" existsObjects:self.param.parentGroup.postDatas];
        }
    }

    self.param.paramValue = valueView.string;
    self.param.comment = comment.stringValue;
    self.param.paramType = types.stringValue;
    
    [[GlobalSetting undoManager] removeAllActionsWithTarget:self];
    if (param) {
        [[GlobalSetting undoManager] removeAllActionsWithTarget:param];
    }
    
    [[NSApplication sharedApplication] stopModal];
    
    if ([pEditDelegate respondsToSelector:@selector(paramEditDidFinished:)])
    {
        [pEditDelegate paramEditDidFinished:self];
    }
    return YES;
}

-(IBAction)browserFileAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
//    openPanel.allowedFileTypes = [NSArray arrayWithObject:@"plist"];
    NSInteger result = [openPanel runModal];
    if (result == NSFileHandlingPanelOKButton)
    {
//        self.param.filename = openPanel.URL.path;
        [self.param setValue:openPanel.URL.path forKey:@"filename"];
    }
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    NSInteger a = types.indexOfSelectedItem;
    if (a == 1)
    {
        //type=file
        [self.param setValue:@"" forKey:@"paramValue"];
        [valueView setEditable:NO];
        [browserBtn setEnabled:YES];
    }
    else
    {
        //type=string
        [self.param setValue:@"" forKey:@"filename"];
        [valueView setEditable:YES];
        [browserBtn setEnabled:NO];
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    if (!self.pUndoManager) {
        self.pUndoManager = [[[NSUndoManager alloc] init] autorelease];
    }
    return self.pUndoManager;
}
@end
