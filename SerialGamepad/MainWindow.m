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

@synthesize portList, connectButton, createButton, level1, level2, level3, level4, level5, level6;

- (IBAction)connectButtonPressed:(id)sender {
}

- (IBAction)createButtonPressed:(id)sender {
}

- (void)populatePortList {
    NSArray *ports = [Serial listSerialPorts];
    
    [portList removeAllItems];
    [portList addItemsWithTitles:ports];
}

@end
