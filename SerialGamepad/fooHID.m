//
//  fooHID.m
//  SerialGamepad
//
//  Created by Thomas Buck on 14.12.15.
//  Copyright © 2015 xythobuz. All rights reserved.
//

#import <IOKit/IOKitLib.h>

#import "fooHID.h"

#define CHANNELS 6
#define CHANNELMAXIMUM 1022
#define CHANNELOFFSET (CHANNELMAXIMUM / 2)

#define FOOHID_NAME "it_unbit_foohid"
#define FOOHID_CREATE 0
#define FOOHID_DESTROY 1
#define FOOHID_SEND 2
#define FOOHID_LIST 3
#define VIRTUAL_DEVICE_NAME "Virtual Serial Transmitter"
#define VIRTUAL_DEVICE_SN "SN  123456"

int foohidInit();
void foohidClose();
void foohidSend(uint16_t *data);

@implementation fooHID

+ (NSInteger)init {
    return foohidInit();
}

+ (void)close {
    return foohidClose();
}

+ (void)send:(NSArray *)data {
    if ([data count] < CHANNELS) {
        NSLog(@"Not enough data values to send (%lu)!\n", (unsigned long)[data count]);
    } else {
        uint16_t buffer[CHANNELS];
        for (int i = 0; i < CHANNELS; i++) {
            buffer[i] = [((NSNumber *)[data objectAtIndex:i]) integerValue];
        }
        foohidSend(buffer);
    }
}

@end

struct gamepad_report_t {
    int16_t leftX;
    int16_t leftY;
    int16_t rightX;
    int16_t rightY;
    int16_t aux1;
    int16_t aux2;
};

static io_connect_t connector;
static uint64_t deviceName = 0, deviceNameLength;
static uint64_t deviceSN = 0, deviceSNLength;
static struct gamepad_report_t gamepad;

/*
 * This is my USB HID Descriptor for this emulated Gamepad.
 * For more informations refer to:
 * http://eleccelerator.com/tutorial-about-usb-hid-report-descriptors/
 * http://www.usb.org/developers/hidpage#HID%20Descriptor%20Tool
 */
static char report_descriptor[36] = {
    0x05, 0x01,                    // USAGE_PAGE (Generic Desktop)
    0x09, 0x05,                    // USAGE (Game Pad)
    0xa1, 0x01,                    // COLLECTION (Application)
    0xa1, 0x00,                    //   COLLECTION (Physical)
    0x05, 0x01,                    //     USAGE_PAGE (Generic Desktop)
    0x09, 0x30,                    //     USAGE (X)
    0x09, 0x31,                    //     USAGE (Y)
    0x09, 0x32,                    //     USAGE (Z)
    0x09, 0x33,                    //     USAGE (Rx)
    0x09, 0x34,                    //     USAGE (Ry)
    0x09, 0x35,                    //     USAGE (Rz)
    0x16, 0x01, 0xfe,              //     LOGICAL_MINIMUM (-511)
    0x26, 0xff, 0x01,              //     LOGICAL_MAXIMUM (511)
    0x75, 0x10,                    //     REPORT_SIZE (16)
    0x95, 0x06,                    //     REPORT_COUNT (6)
    0x81, 0x02,                    //     INPUT (Data,Var,Abs)
    0xc0,                          //     END_COLLECTION
    0xc0                           // END_COLLECTION
};

int foohidInit() {
    NSLog(@"Searching for foohid Kernel extension...\n");
    
    // get a reference to the IOService
    io_iterator_t iterator;
    kern_return_t ret = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                     IOServiceMatching(FOOHID_NAME), &iterator);
    if (ret != KERN_SUCCESS) {
        NSLog(@"Unable to access foohid IOService\n");
        return 1;
    }
    
    int found = 0;
    io_service_t service;
    while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
        ret = IOServiceOpen(service, mach_task_self(), 0, &connector);
        if (ret == KERN_SUCCESS) {
            found = 1;
            break;
        }
    }
    IOObjectRelease(iterator);
    if (!found) {
        NSLog(@"Unable to open foohid IOService\n");
        return 1;
    }
    
    NSLog(@"Creating virtual HID device...\n");
    
    if (deviceName == 0) {
        deviceName = (uint64_t)strdup(VIRTUAL_DEVICE_NAME);
        deviceNameLength = strlen((char *)deviceName);
    }

    if (deviceSN == 0) {
        deviceSN = (uint64_t)strdup(VIRTUAL_DEVICE_SN);
        deviceSNLength = strlen((char *)deviceSN);
    }
    
    uint64_t input[8];
    input[0] = deviceName;
    input[1] = deviceNameLength;

    input[2] = (uint64_t)report_descriptor;
    input[3] = sizeof(report_descriptor);

    input[4] = deviceSN;
    input[5] = deviceSNLength;

    input[6] = (uint64_t)2; // vendor ID
    input[7] = (uint64_t)3; // device ID

    ret = IOConnectCallScalarMethod(connector, FOOHID_CREATE, input, 8, NULL, 0);
    if (ret != KERN_SUCCESS) {
        printf("Unable to create virtual HID device\n");
        return 1;
    }
    
    return 0;
}

void foohidClose() {
    NSLog(@"Destroying virtual HID device\n");
    
    uint64_t input[2];
    input[0] = deviceName;
    input[1] = deviceNameLength;
    
    kern_return_t ret = IOConnectCallScalarMethod(connector, FOOHID_DESTROY, input, 2, NULL, 0);
    if (ret != KERN_SUCCESS) {
        NSLog(@"Unable to destroy virtual HID device\n");
    }
}

void foohidSend(uint16_t *data) {
    for (int i = 0; i < CHANNELS; i++) {
        if (data[i] > CHANNELMAXIMUM) {
            data[i] = CHANNELMAXIMUM;
        }
    }
    
    gamepad.leftX = data[3] - CHANNELOFFSET;
    gamepad.leftY = data[2] - CHANNELOFFSET;
    gamepad.rightX = data[0] - CHANNELOFFSET;
    gamepad.rightY = data[1] - CHANNELOFFSET;
    gamepad.aux1 = data[4] - CHANNELOFFSET;
    gamepad.aux2 = data[5] - CHANNELOFFSET;
    
    /*
     NSLog(@"Sending data packet:\n");
     NSLog(@"Left X: %d\n", gamepad.leftX);
     NSLog(@"Left Y: %d\n", gamepad.leftY);
     NSLog(@"Right X: %d\n", gamepad.rightX);
     NSLog(@"Right Y: %d\n", gamepad.rightY);
     NSLog(@"Aux 1: %d\n", gamepad.aux1);
     NSLog(@"Aux 2: %d\n", gamepad.aux2);
     */
    
    uint64_t input[4];
    input[0] = deviceName;
    input[1] = deviceNameLength;
    input[2] = (uint64_t)&gamepad;
    input[3] = sizeof(struct gamepad_report_t);
    
    kern_return_t ret = IOConnectCallScalarMethod(connector, FOOHID_SEND, input, 4, NULL, 0);
    if (ret != KERN_SUCCESS) {
        NSLog(@"Unable to send packet to virtual HID device\n");
    }
}
