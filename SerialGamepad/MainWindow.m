//
//  MainWindow.m
//  SerialGamepad
//
//  Created by Thomas Buck on 14.12.15.
//  Copyright © 2015 xythobuz. All rights reserved.
//

#import "MainWindow.h"

#import "Serial.h"

@implementation MainWindow

@synthesize portList, connectButton, createButton;
@synthesize level1, level2, level3, level4, level5, level6;
@synthesize serialThread;

- (IBAction)connectButtonPressed:(id)sender {
    if (serialThread == nil) {
        serialThread = [[Thread alloc] init];
        [serialThread setName:@"Serial Communication"];
        [serialThread setPortName:[portList titleOfSelectedItem]];
        
        if ([serialThread openPort] != 0) {
            serialThread = nil;
        } else {
            [serialThread start];
            [connectButton setTitle:@"Disconnect"];
        }
    } else {
        [serialThread setRunning:NO];
        // TODO disable button, thread should call back when closed
        // so we can set serialThread to nil then
        serialThread = nil;
        [connectButton setTitle:@"Connect"];
    }
}

- (IBAction)createButtonPressed:(id)sender {
    
}

- (void)populatePortList {
    NSArray *ports = [Serial listSerialPorts];
    if ([ports count] > 0) {
        [portList removeAllItems];
        [portList addItemsWithTitles:ports];
        [portList setEnabled:YES];
        [connectButton setEnabled:YES];
    } else {
        NSLog(@"Couldn't find any serial ports!\n");
    }
}

@end
