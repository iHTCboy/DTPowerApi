//
//  AppDelegate.m
//  DTPowerApi
//
//  Created by leks on 12-12-26.
//  Copyright (c) 2012年 leks. All rights reserved.
//

#import "AppDelegate.h"
#import "PAWindowController.h"
#import "Global.h"
void UncaughtExceptionHandler(NSException *exception);

@implementation AppDelegate

- (void)dealloc
{
    [super dealloc];
}

-(void)initGlobal
{
    gNetworkManager = [[PANetworkManager alloc] init];
    gGlobalSetting = [[GlobalSetting alloc] init];
}

-(void)releaseGlobal
{
    [gNetworkManager release];
    gNetworkManager = nil;
    [gGlobalSetting release];
    gGlobalSetting = nil;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self initGlobal];
    // Insert code here to initialize your application
//    NSSetUncaughtExceptionHandler (&UncaughtExceptionHandler);
    if (!window) {
        window = [[PAWindowController alloc] initWithWindowNibName:@"PAWindowController"];
    }
    
    [window showWindow:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    if (filenames.count > 0) {
        NSString *path = [filenames objectAtIndex:0];
        if (!window) {
            window = [[PAWindowController alloc] initWithWindowNibName:@"PAWindowController"];
        }
        
        window.openPath = path;
        [window openFile:path];
    }
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    if (!window) {
        window = [[PAWindowController alloc] initWithWindowNibName:@"PAWindowController"];
    }
    window.openPath = filename;
    [window openFile:filename];
    return YES;
}

-(void)reloadItem:(NSUInteger)tag title:(NSString*)title
{
    if (tag == 30001)
    {
        [projectNavigatorItem setTitle:title];
    }
    else if (tag == 30002)
    {
        [logPanelItem setTitle:title];
    }
    else if (tag == 30003)
    {
        [inspectorItem setTitle:title];
    }
}



@end

void UncaughtExceptionHandler(NSException *exception)
{
    
    NSArray *arr = [exception callStackSymbols];
    NSString *reason = [exception reason];
    NSString *name = [exception name];
    NSString *urlStr = [NSString stringWithFormat:@"Error Details:<br>%@<br>--------------------------<br>%@<br>---------------------<br>%@",
                        name,reason,[arr componentsJoinedByString:@"<br>"]];
    
    //    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"$$$$$$$$$$$$$$$$$$$$$$$\n\n%@\n\n",urlStr);
    NSLog(@"Log write success.");
    //    [[UIApplication sharedApplication] openURL:url];
}
