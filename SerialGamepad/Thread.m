//
//  Thread.m
//  SerialGamepad
//
//  Created by Thomas Buck on 15.12.15.
//  Copyright © 2015 xythobuz. All rights reserved.
//

#import <termios.h>
#import <fcntl.h>
#import <unistd.h>

#import "Thread.h"
#import "fooHID.h"
#import "MainWindow.h"

#define CHANNELS 6
#define TESTCHANNEL 2
#define PACKETSIZE 18
#define HEADERBYTES 2
#define CHECKSUMBYTES 2
#define PAYLOADBYTES (PACKETSIZE - HEADERBYTES - CHECKSUMBYTES)
#define HEADERBYTE_A 85
#define HEADERBYTE_B 252

enum ThreadState {
    READ_FIRST_BYTE,
    READ_SECOND_BYTE,
    READ_PAYLOAD,
    READ_CHECKSUM
};

@implementation Thread

@synthesize running, fd, portName, mainWindow;

- (id)initWithWindow:(MainWindow *)window {
    self = [super init];
    if (self != nil) {
        mainWindow = window;
    }
    return self;
}

- (NSInteger)openPort {
    if (portName == nil) {
        return 1;
    }
    
    // Open port read-only, without controlling terminal, non-blocking
    fd = open([portName UTF8String], O_RDONLY | O_NOCTTY | O_NONBLOCK);
    if (fd == -1) {
        NSLog(@"Error opening serial port \"%@\"!\n", portName);
        return 1;
    }
    
    fcntl(fd, F_SETFL, 0); // Enable blocking I/O
    
    // Read current settings
    struct termios options;
    tcgetattr(fd, &options);
    
    options.c_lflag = 0;
    options.c_oflag = 0;
    options.c_iflag = 0;
    options.c_cflag = 0;
    
    options.c_cflag |= CS8; // 8 data bits
    options.c_cflag |= CREAD; // Enable receiver
    options.c_cflag |= CLOCAL; // Ignore modem status lines
    
    cfsetispeed(&options, B115200);
    cfsetospeed(&options, B115200);
    
    options.c_cc[VMIN] = 0; // Return even with zero bytes...
    options.c_cc[VTIME] = 1; // ...but only after .1 seconds
    
    // Set new settings
    tcsetattr(fd, TCSANOW, &options);
    tcflush(fd, TCIOFLUSH);
    
    return 0;
}

- (void)main {
    enum ThreadState state = READ_FIRST_BYTE;
    unsigned char c = 0;
    unsigned char buffer[PAYLOADBYTES];
    unsigned char checksum[CHECKSUMBYTES];
    uint16_t channels[CHANNELS + 1];
    int received = 0;
    
    NSLog(@"Connection running...\n");
    
    running = YES;
    while (running) {
        if (state == READ_FIRST_BYTE) {
            if (read(fd, &c, 1) == 1) {
                if (c == HEADERBYTE_A) {
                    state = READ_SECOND_BYTE;
                }
            }
        } else if (state == READ_SECOND_BYTE) {
            if (read(fd, &c, 1) == 1) {
                if (c == HEADERBYTE_B) {
                    state = READ_PAYLOAD;
                    received = 0;
                } else {
                    state = READ_FIRST_BYTE;
                }
            }
        } else if (state == READ_PAYLOAD) {
            ssize_t ret = read(fd, buffer + received, PAYLOADBYTES - received);
            if (ret >= 0) received += ret;
            if (received >= PAYLOADBYTES) {
                state = READ_CHECKSUM;
                received = 0;
            }
        } else if (state == READ_CHECKSUM) {
            ssize_t ret = read(fd, checksum + received, CHECKSUMBYTES - received);
            if (ret >= 0) received += ret;
            if (received >= CHECKSUMBYTES) {
                state = READ_FIRST_BYTE;
                
                uint16_t sum = 0;
                for (int i = 0; i < PAYLOADBYTES; i++) {
                    sum += buffer[i];
                }
                
                if (sum != ((checksum[0] << 8) | checksum[1])) {
                    NSLog(@"Wrong checksum: %d != %d\n", sum, ((checksum[0] << 8) | checksum[1]));
                } else {
                    for (int i = 0; i < (CHANNELS + 1); i++) {
                        channels[i] = buffer[2 * i] << 8;
                        channels[i] |= buffer[(2 * i) + 1];
                    
                        if (i < CHANNELS) {
                            channels[i] -= 1000;
                        }
                    }
                    
                    if (channels[CHANNELS] != channels[TESTCHANNEL]) {
                        NSLog(@"Wrong test channel value: %d != %d\n", channels[CHANNELS], channels[TESTCHANNEL]);
                    }
                    
                    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:CHANNELS];
                    for (int i = 0; i < CHANNELS; i++) {
                        [arr addObject:[[NSNumber alloc] initWithInteger:(NSInteger)channels[i]]];
                    }
                    
                    [mainWindow performSelectorOnMainThread:@selector(setChannels:) withObject:arr waitUntilDone:NO];
                }
            }
        } else {
            NSLog(@"Invalid state?!\n");
            state = READ_FIRST_BYTE;
        }
    }
    
    close(fd);
    NSLog(@"Connection closed...\n");
    fd = -1;
}

@end
