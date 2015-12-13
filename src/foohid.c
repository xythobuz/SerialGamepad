/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * <xythobuz@xythobuz.de> wrote this file.  As long as you retain this notice
 * you can do whatever you want with this stuff. If we meet some day, and you
 * think this stuff is worth it, you can buy me a beer in return.   Thomas Buck
 * ----------------------------------------------------------------------------
 */

#include <stdint.h>
#include <stdio.h>
#include <signal.h>
#include <string.h>

#include <IOKit/IOKitLib.h>

#include "serial.h"

#define BAUDRATE 115200
#define PACKETSIZE 18
#define HEADERBYTES 2
#define HEADERBYTE_A 85
#define HEADERBYTE_B 252
#define CHECKSUMBYTES 2
#define PAYLOADBYTES (PACKETSIZE - HEADERBYTES - CHECKSUMBYTES)
#define CHANNELS 6
#define CHANNELMAXIMUM 1022

#define FOOHID_NAME "it_unbit_foohid"
#define FOOHID_CREATE 0
#define FOOHID_DESTROY 1
#define FOOHID_SEND 2
#define FOOHID_LIST 3
#define VIRTUAL_DEVICE_NAME "Virtual Serial Transmitter"

struct gamepad_report_t {
    int16_t leftX;
    int16_t leftY;
    int16_t rightX;
    int16_t rightY;
    int16_t aux1;
    int16_t aux2;
};

static int running = 1;
static io_iterator_t iterator;
static io_service_t service;
static io_connect_t connect;
static uint64_t input[4];
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

static int foohidInit() {
    // get a reference to the IOService
    kern_return_t ret = IOServiceGetMatchingServices(kIOMasterPortDefault,
                            IOServiceMatching("it_unbit_foohid"), &iterator);
    if (ret != KERN_SUCCESS) {
        printf("Unable to access foohid IOService\n");
        return 1;
    }

    int found = 0;
    while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
        ret = IOServiceOpen(service, mach_task_self(), 0, &connect);
        if (ret == KERN_SUCCESS) {
            found = 1;
            break;
        }
    }
    IOObjectRelease(iterator);
    if (!found) {
        printf("Unable to open foohid IOService\n");
        return 1;
    }

    input[0] = (uint64_t)strdup(VIRTUAL_DEVICE_NAME);
    input[1] = strlen((char*)input[0]);

    input[2] = (uint64_t)report_descriptor;
    input[3] = sizeof(report_descriptor);

    uint32_t output_count = 1;
    uint64_t output = 0;
    ret = IOConnectCallScalarMethod(connect, FOOHID_CREATE, input, 4, &output, &output_count);
    if (ret != KERN_SUCCESS) {
        printf("Unable to create virtual HID device\n");
        return 1;
    }

    return 0;
}

static void foohidClose() {
    uint32_t output_count = 1;
    uint64_t output = 0;
    kern_return_t ret = IOConnectCallScalarMethod(connect, FOOHID_DESTROY, input, 2, &output, &output_count);
    if (ret != KERN_SUCCESS) {
        printf("Unable to destroy virtual HID device\n");
    }
}

static void foohidSend(uint16_t *data) {
    input[2] = (uint64_t)&gamepad;
    input[3] = sizeof(struct gamepad_report_t);

    for (int i = 0; i < CHANNELS; i++) {
        if (data[i] > CHANNELMAXIMUM) {
            data[i] = CHANNELMAXIMUM;
        }
    }

    gamepad.leftX = data[0] - 511;
    gamepad.leftY = data[1] - 511;
    gamepad.rightX = data[2] - 511;
    gamepad.rightY = data[3] - 511;
    gamepad.aux1 = data[4] - 511;
    gamepad.aux2 = data[5] - 511;

    uint32_t output_count = 1;
    uint64_t output = 0;
    kern_return_t ret = IOConnectCallScalarMethod(connect, FOOHID_SEND, input, 4, &output, &output_count);
    if (ret != KERN_SUCCESS) {
        printf("Unable to send packet to virtual HID device\n");
    }
}

static void signalHandler(int signo) {
    running = 0;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Usage:\n\t%s /dev/serial_port\n", argv[0]);
        return 1;
    }

    int fd = serialOpen(argv[1], BAUDRATE);
    if (fd == -1) {
        return 1;
    }

    if (foohidInit() != 0) {
        serialClose(fd);
        return 1;
    }

    if (signal(SIGINT, signalHandler) == SIG_ERR) {
        perror("Couldn't register signal handler");
        return 1;
    }

    while (running != 0) {
        if (serialHasChar(fd)) {
            unsigned char c1;
            serialReadChar(fd, (char*)&c1);
            if (c1 == HEADERBYTE_A) {
                // Found first byte of protocol start
                while (!serialHasChar(fd)) {
                    if (running == 0) {
                        serialClose(fd);
                        return 0;
                    }
                }

                unsigned char c2;
                serialReadChar(fd, (char*)&c2);
                if (c2 == HEADERBYTE_B) {
                    // Protocol start has been found, read payload
                    unsigned char data[PAYLOADBYTES];
                    int read = 0;
                    while ((read < PAYLOADBYTES) && (running != 0)) {
                        read += serialReadRaw(fd, (char*)data + read, PAYLOADBYTES - read);
                    }

                    // Read 16bit checksum
                    unsigned char checksumData[CHECKSUMBYTES];
                    read = 0;
                    while ((read < CHECKSUMBYTES) && (running != 0)) {
                        read += serialReadRaw(fd, (char*)checksumData + read,
                                CHECKSUMBYTES - read);
                    }

                    // Check if checksum matches
                    uint16_t checksum = 0;
                    for (int i = 0; i < PAYLOADBYTES; i++) {
                        checksum += data[i];
                    }

                    if (checksum != ((checksumData[0] << 8) | checksumData[1])) {
                        printf("Wrong checksum: %d != %d\n",
                                checksum, ((checksumData[0] << 8) | checksumData[1]));
                    } else {
                        // Decode channel values
                        uint16_t buff[CHANNELS + 1];
                        for (int i = 0; i < (CHANNELS + 1); i++) {
                            buff[i] = data[2 * i] << 8;
                            buff[i] |= data[(2 * i) + 1];
                        }

                        foohidSend(buff);
                    }
                }
            }
        }
    }

    serialClose(fd);
    foohidClose();

    return 0;
}

