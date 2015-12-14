//
//  AppDelegate.m
//  SerialGamepad
//
//  Created by Thomas Buck on 14.12.15.
//  Copyright © 2015 xythobuz. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindow.h"

@interface AppDelegate ()

@property (weak) IBOutlet MainWindow *window;

@end

@implementation AppDelegate

@synthesize window;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [window populatePortList];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
