//
//  MainWindow.m
//  SerialGamepad
//
//  Created by Thomas Buck on 14.12.15.
//  Copyright © 2015 xythobuz. All rights reserved.
//

#import "MainWindow.h"

#import "fooHID.h"
#import "Serial.h"
#import "Thread.h"

@implementation MainWindow

@synthesize portList, connectButton, createButton;
@synthesize level1, level2, level3, level4, level5, level6;
@synthesize serialThread, gamepadCreated;

- (id)init {
    self = [super init];
    if (self != nil) {
        serialThread = nil;
        gamepadCreated = NO;
        [self setDelegate:self];
    }
    return self;
}

- (BOOL)windowShouldClose:(id)sender {
    if (gamepadCreated) {
        [fooHID close];
        gamepadCreated = NO;
    }
    
    if (serialThread != nil) {
        // Stop thread and wait for it to finish
        [serialThread setRunning:NO];
        while ([serialThread isFinished] == NO) {
            usleep(1000);
        }
    }
    
    return YES;
}

- (IBAction)connectButtonPressed:(id)sender {
    if (serialThread == nil) {
        serialThread = [[Thread alloc] initWithWindow:self];
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
        serialThread = nil;
        [connectButton setTitle:@"Connect"];
    }
}

- (IBAction)createButtonPressed:(id)sender {
    if (gamepadCreated) {
        [fooHID close];
        gamepadCreated = NO;
        [createButton setTitle:@"Create"];
    } else {
        if ([fooHID init] == 0) {
            gamepadCreated = YES;
            [createButton setTitle:@"Destroy"];
        }
    }
}

- (void)populatePortList {
    NSArray *ports = [Serial listSerialPorts];
    if ([ports count] > 0) {
        [portList removeAllItems];
        [portList addItemsWithTitles:ports];
        
        for (int i = 0; i < [ports count]; i++) {
            if ([[ports objectAtIndex:i] isEqualToString:@"/dev/tty.SLAB_USBtoUART"]) {
                [portList selectItemAtIndex:i];
            }
        }
        
        [portList setEnabled:YES];
        [connectButton setEnabled:YES];
        [createButton setEnabled:YES];
    } else {
        NSLog(@"Couldn't find any serial ports!\n");
    }
}

- (void)setChannels:(id)data {
    if ([data count] < 6) {
        NSLog(@"Not enough channel data (%lu)?!\n", (unsigned long)[data count]);
    } else {
        [level1 setDoubleValue:[[data objectAtIndex:0] doubleValue]];
        [level2 setDoubleValue:[[data objectAtIndex:1] doubleValue]];
        [level3 setDoubleValue:[[data objectAtIndex:2] doubleValue]];
        [level4 setDoubleValue:[[data objectAtIndex:3] doubleValue]];
        [level5 setDoubleValue:[[data objectAtIndex:4] doubleValue]];
        [level6 setDoubleValue:[[data objectAtIndex:5] doubleValue]];
        
        if (gamepadCreated) {
            [fooHID send:data];
        }
    }
}

@end
