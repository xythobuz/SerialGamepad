//
//  MainWindow.h
//  SerialGamepad
//
//  Created by Thomas Buck on 14.12.15.
//  Copyright © 2015 xythobuz. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Thread;

@interface MainWindow : NSWindow <NSWindowDelegate>

@property (weak) IBOutlet NSPopUpButton *portList;
@property (weak) IBOutlet NSButton *connectButton;
@property (weak) IBOutlet NSButton *createButton;
@property (weak) IBOutlet NSLevelIndicator *level1;
@property (weak) IBOutlet NSLevelIndicator *level2;
@property (weak) IBOutlet NSLevelIndicator *level3;
@property (weak) IBOutlet NSLevelIndicator *level4;
@property (weak) IBOutlet NSLevelIndicator *level5;
@property (weak) IBOutlet NSLevelIndicator *level6;

@property (strong) Thread *serialThread;

- (void)populatePortList;
- (void)setChannels:(id)data;

@end
