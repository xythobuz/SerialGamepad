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

@implementation Thread

@synthesize running, fd, portName;

- (NSInteger)openPort {
    if (portName == nil) {
        return 1;
    }
    
    fd = open([portName UTF8String], O_RDONLY | O_NOCTTY | O_NONBLOCK);
    if (fd == -1) {
        NSLog(@"Error opening serial port \"%@\"!\n", portName);
        return 1;
    }
    
    fcntl(fd, F_SETFL, 0);
    
    struct termios options;
    tcgetattr(fd, &options);
    
    options.c_lflag = 0;
    options.c_oflag = 0;
    options.c_iflag = 0;
    options.c_cflag = 0;
    
    options.c_cflag |= CS8;
    options.c_cflag |= CREAD;
    options.c_cflag |= CLOCAL;
    
    cfsetispeed(&options, B115200);
    cfsetospeed(&options, B115200);
    
    options.c_cc[VMIN] = 0;
    options.c_cc[VTIME] = 1;
    
    tcsetattr(fd, TCSANOW, &options);
    tcflush(fd, TCIOFLUSH);
    
    return 0;
}

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

- (void)main {
    enum ThreadState state = READ_FIRST_BYTE;
    unsigned char c = 0;
    unsigned char buffer[PACKETSIZE];
    unsigned char checksum[CHECKSUMBYTES];
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
                
                // TODO got something
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
