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
#include <unistd.h>
#include <stdlib.h>

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
#define TESTCHANNEL 2
#define CHANNELMAXIMUM 1022

#define FOOHID_NAME "it_unbit_foohid"
#define FOOHID_CREATE 0
#define FOOHID_DESTROY 1
#define FOOHID_SEND 2
#define FOOHID_LIST 3

#define VIRTUAL_DEVICE_NAME "FrSky Joystick"
#define VIRTUAL_DEVICE_SERIAL "00000000001B"
#define VIRTUAL_VID 0x0483
#define VIRTUAL_PID 0x5710

struct gamepad_report_t {
    //bit 0 - button 1, bit 1 - button 2, ..., mapped to channels 9-16, on if channel > 0
    uint8_t buttons1;
    uint8_t buttons2; // mapped to channels 17-24, on if channel > 0
    uint8_t buttons3; // mapped to channels 25-32, on if channel > 0
    int8_t X;  //analog value, mapped to channel 1
    int8_t Y;  //analog value, mapped to channel 2
    int8_t Z;  //analog value, mapped to channel 3
    int8_t Rx; //analog value, mapped to channel 4
    int8_t Ry; //analog value, mapped to channel 5
    int8_t Rz; //analog value, mapped to channel 6
    int8_t S1; //analog value, mapped to channel 7
    int8_t S2; //analog value, mapped to channel 8
};

static int running = 1;
static io_iterator_t iterator;
static io_service_t service;
static io_connect_t connect;
#define input_count 8
static uint64_t input[input_count];
static struct gamepad_report_t gamepad;

// From Taranis:
// https://github.com/opentx/opentx/blob/03b65b06b6cec2d2b64dfb0f436eda155274841d/radio/src/targets/common/arm/stm32/usbd_hid_joystick.c
static const uint8_t report_descriptor[] = {
    0x05, 0x01,                    //     USAGE_PAGE (Generic Desktop)
    0x09, 0x05,                    //     USAGE (Game Pad)
    0xa1, 0x01,                    //     COLLECTION (Application)
    0xa1, 0x00,                    //       COLLECTION (Physical)
    0x05, 0x09,                    //         USAGE_PAGE (Button)
    0x19, 0x01,                    //         USAGE_MINIMUM (Button 1)
    0x29, 0x18,                    //         USAGE_MAXIMUM (Button 24)
    0x15, 0x00,                    //         LOGICAL_MINIMUM (0)
    0x25, 0x01,                    //         LOGICAL_MAXIMUM (1)
    0x95, 0x18,                    //         REPORT_COUNT (24)
    0x75, 0x01,                    //         REPORT_SIZE (1)
    0x81, 0x02,                    //         INPUT (Data,Var,Abs)
    0x05, 0x01,                    //         USAGE_PAGE (Generic Desktop)
    0x09, 0x30,                    //         USAGE (X)
    0x09, 0x31,                    //         USAGE (Y)
    0x09, 0x32,                    //         USAGE (Z)
    0x09, 0x33,                    //         USAGE (Rx)
    0x09, 0x34,                    //         USAGE (Ry)
    0x09, 0x35,                    //         USAGE (Rz)
    0x09, 0x36,                    //         USAGE (Slider)
    0x09, 0x36,                    //         USAGE (Slider)
    0x15, 0x81,                    //         LOGICAL_MINIMUM (-127)
    0x25, 0x7f,                    //         LOGICAL_MAXIMUM (127)
    0x75, 0x08,                    //         REPORT_SIZE (8)
    0x95, 0x08,                    //         REPORT_COUNT (8)
    0x81, 0x02,                    //         INPUT (Data,Var,Abs)
    0xc0,                          //       END_COLLECTION
    0xc0                           //     END_COLLECTION
};

static int foohidPrintDevices() {
    uint32_t output_count = 2;
    uint64_t output[2] = { 0, 0 };

	uint16_t buf_len = 4096;
	char *buf = malloc(buf_len);
	if (!buf) {
        printf("memory error\n");
		return 1;
	}

    uint64_t input[2];
	while (1) {
        input[0] = (uint64_t) buf;
        input[1] = (uint64_t) buf_len;
        kern_return_t ret = IOConnectCallScalarMethod(connect, FOOHID_LIST, input, 2, output, &output_count);
        if (ret != KERN_SUCCESS) {
            free(buf);
            printf("unable to list hid devices\n");
            return 1;
        }

        // all is fine
        if (output[0] == 0) {
            printf("--\n");
            printf("fooHID devices: (%llu)\n", output[1]);
            char *ptr = buf;
            for(uint64_t i = 0; i < output[1]; i++) {
                printf("%s\n", ptr);
                ptr += strlen(ptr) + 1;
            }
            printf("--\n");
            free(buf);
            return ret;
        }

        // realloc memory
        buf_len = output[0];
        char *tmp = realloc(buf, buf_len);
        if (!tmp) {
            free(buf);
            printf("unable to allocate memory\n");
            return 1;
        }
        buf = tmp;
	}

    return 0;
}

static int foohidInit() {
    printf("Searching for foohid Kernel extension...\n");

    // get a reference to the IOService
    kern_return_t ret = IOServiceGetMatchingServices(kIOMasterPortDefault,
                            IOServiceMatching(FOOHID_NAME), &iterator);
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

    //foohidPrintDevices();
    printf("Creating virtual HID device...\n");

    input[0] = (uint64_t)strdup(VIRTUAL_DEVICE_NAME);
    input[1] = strlen((char*)input[0]);

    input[2] = (uint64_t)report_descriptor;
    input[3] = sizeof(report_descriptor);

    input[4] = (uint64_t)strdup(VIRTUAL_DEVICE_SERIAL);
    input[5] = strlen((char*)input[4]);

    input[6] = (uint64_t)VIRTUAL_VID;
    input[7] = (uint64_t)VIRTUAL_PID;

    ret = IOConnectCallScalarMethod(connect, FOOHID_CREATE, input, input_count, NULL, 0);
    if (ret != KERN_SUCCESS) {
        printf("Unable to create virtual HID device\n");
        return 1;
    }

    return 0;
}

static void foohidClose() {
    printf("Destroying virtual HID device\n");

    kern_return_t ret = IOConnectCallScalarMethod(connect, FOOHID_DESTROY, input, 2, NULL, 0);
    if (ret != KERN_SUCCESS) {
        printf("Unable to destroy virtual HID device\n");
    }
}

static void foohidSend(uint16_t *data) {
    for (int i = 0; i < CHANNELS; i++) {
        if (data[i] > CHANNELMAXIMUM) {
            data[i] = CHANNELMAXIMUM;
        }
    }

    gamepad.X = (data[3] - 511) / 4;
    gamepad.Y = (data[2] - 511) / 4;
    gamepad.Z = (data[0] - 511) / 4;
    gamepad.Rx = (data[1] - 511) / 4;
    gamepad.Ry = (data[4] - 511) / 4;
    gamepad.Rz = (data[5] - 511) / 4;

    input[2] = (uint64_t)&gamepad;
    input[3] = sizeof(struct gamepad_report_t);

    kern_return_t ret = IOConnectCallScalarMethod(connect, FOOHID_SEND, input, 4, NULL, 0);
    if (ret != KERN_SUCCESS) {
        printf("Unable to send packet to virtual HID device\n");
    }
}

static void signalHandler(int signo) {
    running = 0;
    printf("\n");
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Usage:\n\t%s /dev/serial_port\n", argv[0]);
        return 1;
    }

    printf("Opening serial port...\n");

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

    printf("Entering main-loop...\n");

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

                            if (i < CHANNELS) {
                                buff[i] -= 1000;
                            }
                        }

                        // Check Test Channel Value
                        if (buff[CHANNELS] != buff[TESTCHANNEL]) {
                            printf("Wrong test channel value: %d != %d\n",
                                   buff[CHANNELS], buff[TESTCHANNEL]);
                        }

                        foohidSend(buff);
                    }
                }
            }
        }

        usleep(1000);
    }

    printf("Closing serial port...\n");
    serialClose(fd);
    foohidClose();

    return 0;
}

