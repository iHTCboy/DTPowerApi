//
//  PropertyWindowController.m
//  DTPowerApi
//
//  Created by leks on 13-1-29.
//  Copyright (c) 2013年 leks. All rights reserved.
//

#import "PropertyWindowController.h"
#import "Global.h"
#import "PAProject.h"
#import "PABean.h"
#import "PAParamGroup.h"

@interface PropertyWindowController ()

@end

@implementation PropertyWindowController
@synthesize property;
@synthesize project;
@synthesize proDelegate;
@synthesize firstEdit;

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [property release];
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
    edited = NO;
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if (firstEdit)
        {
//            if (note.object == nameField)
//            {
//                [keyField setStringValue:nameField.stringValue];
//            }
//            else if (note.object == keyField)
//            {
//                [nameField setStringValue:keyField.stringValue];
//            }
            edited = YES;
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidEndEditingNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if (firstEdit && edited)
        {
            if (note.object == nameField ||
                note.object == keyField)
            {
                firstEdit = NO;
            }
        }
    }];
    
    [self checkPropertyType:property.fieldType];
}

-(void)reloadProperty:(PAProperty*)p
{
    self.property = p;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(valueExistsNotification:) name:PANOTIFICATION_OBJECT_VALUE_EXISTS object:nil];
}

-(void)valueExistsNotification:(NSNotification*)notification
{
    NSDictionary *dict = notification.object;
    NSString *object_type = [dict objectForKey:@"object_type"];
    NSString *key = [dict objectForKey:@"key"];
    NSString *value = [dict objectForKey:@"value"];
    id object = [dict objectForKey:@"object"];
    
    if (object != self.property) {
        return;
    }
    
    if ([object_type isEqualToString:[PAProperty className]])
    {
        if ([key isEqualToString:@"fieldName"])
        {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Variable name already exists!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
            [alert runModal];
            keyField.stringValue = value;
        }
        else if ([key isEqualToString:@"name"])
        {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Property name already exists!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
            [alert runModal];
            nameField.stringValue = value;
        }
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    self.property.name = [self.property.parentBean newPropertyValueByValue:nameField.stringValue forKey:@"name" except:self.property];
    self.property.fieldName = [self.property.parentBean newPropertyValueByValue:keyField.stringValue forKey:@"fieldName" except:self.property];
    self.property.fieldType = typeCombo.stringValue;
    self.property.defaultValue = defaultField.stringValue;
    self.property.comment = commentView.stringValue;
    
    if ([self.property.fieldType isEqualToString:PAFIELD_TYPE_ARRAY] ||
        [self.property.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
    {
        if (self.property.beanName.length == 0)
        {
            self.property.beanName = PAFIELD_TYPE_STRING;
        }
    }

    [[GlobalSetting undoManager] removeAllActionsWithTarget:self];
    if (property) {
        [[GlobalSetting undoManager] removeAllActionsWithTarget:property];
    }
    
    [[NSApplication sharedApplication] stopModal];
    
    if ([proDelegate respondsToSelector:@selector(propertyEditDidFinished:)])
    {
        [proDelegate propertyEditDidFinished:self];
    }
    return YES;
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    if (aComboBox.tag == 1) {
        return 4;
    }
    
    if ([property.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
    {
        return project.beans.allChildren.count;
    }
    else if ([property.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
    {
        return project.beans.allChildren.count+2;
    }
    
    return 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    if (aComboBox.tag == 1) {
        NSArray *tmp = @[PAFIELD_TYPE_STRING, PAFIELD_TYPE_NUMBER, PAFIELD_TYPE_OBJECT, PAFIELD_TYPE_ARRAY];
        return [tmp objectAtIndex:index];
    }
    else
    {
        if ([property.fieldType isEqualToString:PAFIELD_TYPE_OBJECT])
        {
            PABean *bean = [project.beans.allChildren objectAtIndex:index];
            return bean.beanName;
        }
        else if ([property.fieldType isEqualToString:PAFIELD_TYPE_ARRAY])
        {
            if (index == 0) {
                return PAFIELD_TYPE_STRING;
            }
            else if (index == 1)
            {
                return PAFIELD_TYPE_NUMBER;
            }
            
            PABean *bean = [project.beans.allChildren objectAtIndex:index-2];
            return bean.beanName;
        }
    }
    
    return nil;
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedIndex = [typeCombo indexOfSelectedItem];
    if (selectedIndex < 0 || selectedIndex > 3) {
        return ;
    }
    
    NSString *strValue = [self comboBox:typeCombo objectValueForItemAtIndex:[typeCombo indexOfSelectedItem]];
    [self checkPropertyType:strValue];
}

-(void)checkPropertyType:(NSString*)type
{
    if ([type isEqualToString:PAFIELD_TYPE_OBJECT])
    {
        [beanCombo setEnabled:YES];
        if (property.beanName.length == 0)
        {
            if (project.beans.allChildren.count > 0)
            {
                PABean *bean = [project.beans.allChildren objectAtIndex:0];
//                property.beanName = bean.beanName;
                [property setValue:bean.beanName forKey:@"beanName"];
            }
        }
    }
    else if ([type isEqualToString:PAFIELD_TYPE_ARRAY])
    {
        [beanCombo setEnabled:YES];
        if (property.beanName.length == 0)
        {
//            property.beanName = PAFIELD_TYPE_STRING;
            [property setValue:PAFIELD_TYPE_STRING forKey:@"beanName"];
        }
    }
    else
    {
//        property.beanName = @"";
        [property setValue:@"" forKey:@"beanName"];
        [beanCombo setEnabled:NO];
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [GlobalSetting undoManager];
}
@end
