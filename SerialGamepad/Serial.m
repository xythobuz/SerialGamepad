//
//  Serial.m
//  SerialGamepad
//
//  For more informations refer to this document:
//  https://developer.apple.com/library/mac/documentation/DeviceDrivers/Conceptual/WorkingWSerial/WWSerial_SerialDevs/SerialDevices.html
//
//  Created by Thomas Buck on 14.12.15.
//  Copyright © 2015 xythobuz. All rights reserved.
//

#import <IOKit/serial/IOSerialKeys.h>

#import "Serial.h"

@implementation Serial

+ (NSArray *)listSerialPorts {
    // Get Iterator with all serial ports
    io_iterator_t serialPortIterator;
    kern_return_t kernResult = findSerialPorts(&serialPortIterator);
    
    // Create 2D array
    char **portList;
    portList = malloc(100 * sizeof(char *));
    for (int i = 0; i < 100; i++) portList[i] = malloc(200 * sizeof(char));
    
    // Copy device name into C-String array
    kernResult = getSerialPortPath(serialPortIterator, portList, 100, 200);
    IOObjectRelease(serialPortIterator);
    
    // Copy contents into NSString Array
    NSString *stringList[100];
    NSUInteger realCount = 0;
    while (portList[realCount] != NULL) {
        stringList[realCount] = [NSString stringWithCString:portList[realCount] encoding:NSUTF8StringEncoding];
        realCount++;
    }
    
    // Destroy 2D array
    for (int i = 0; i < 100; i++) free(portList[i]);
    free(portList);
    
    // And return them as NSArray
    return [[NSArray alloc] initWithObjects:stringList count:realCount];
}

@end

kern_return_t findSerialPorts(io_iterator_t *matches) {
    kern_return_t kernResult;
    mach_port_t masterPort;
    CFMutableDictionaryRef classesToMatch;
    
    kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult) {
        NSLog(@"IOMasterPort returned %d\n", kernResult);
        return kernResult;
    }
    
    // Serial devices are instances of class IOSerialBSDClient.
    classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    if (classesToMatch == NULL) {
        NSLog(@"IOServiceMatching returned a NULL dictionary.\n");
    } else {
        CFDictionarySetValue(classesToMatch,
                             CFSTR(kIOSerialBSDTypeKey),
                             CFSTR(kIOSerialBSDRS232Type));
        
        // Each serial device object has a property with key
        // kIOSerialBSDTypeKey and a value that is one of
        // kIOSerialBSDAllTypes, kIOSerialBSDModemType,
        // or kIOSerialBSDRS232Type. You can change the
        // matching dictionary to find other types of serial
        // devices by changing the last parameter in the above call
        // to CFDictionarySetValue.
    }
    
    kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, matches);
    if (KERN_SUCCESS != kernResult) {
        NSLog(@"IOServiceGetMatchingServices returned %d\n", kernResult);
        return kernResult;
    }
    
    return kernResult;
}

kern_return_t getSerialPortPath(io_iterator_t serialPortIterator, char **deviceFilePath, CFIndex maxPathCount, CFIndex maxPathSize) {
    io_object_t modemService;
    kern_return_t kernResult = KERN_FAILURE;
    CFIndex i = 0;
    
    while ((modemService = IOIteratorNext(serialPortIterator)) && (i < (maxPathCount - 1))) {
        CFTypeRef   deviceFilePathAsCFString;
        
        // Get the callout device's path (/dev/cu.xxxxx).
        // The callout device should almost always be
        // used. You would use the dialin device (/dev/tty.xxxxx) when
        // monitoring a serial port for
        // incoming calls, for example, a fax listener.
        
        deviceFilePathAsCFString = IORegistryEntryCreateCFProperty(modemService,
                                                                   CFSTR(kIODialinDeviceKey),
                                                                   kCFAllocatorDefault,
                                                                   0);
        if (deviceFilePathAsCFString) {
            Boolean result;
            
            deviceFilePath[i][0] = '\0';
            
            // Convert the path from a CFString to a NULL-terminated C string
            // for use with the POSIX open() call.
            
            result = CFStringGetCString(deviceFilePathAsCFString,
                                        deviceFilePath[i],
                                        maxPathSize,
                                        kCFStringEncodingASCII);
            CFRelease(deviceFilePathAsCFString);
            
            if (result) {
                NSLog(@"BSD path: %s\n", deviceFilePath[i]);
                i++;
                kernResult = KERN_SUCCESS;
            }
        }
        
        // Release the io_service_t now that we are done with it.
        
        (void) IOObjectRelease(modemService);
    }
    
    deviceFilePath[i] = NULL;
    
    return kernResult;
}
