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
#include <unistd.h>

#include "serial.h"

#define BAUDRATE 115200
#define PACKETSIZE 18
#define HEADERBYTES 2
#define HEADERBYTE_A 85
#define HEADERBYTE_B 252
#define CHECKSUMBYTES 2
#define PAYLOADBYTES (PACKETSIZE - HEADERBYTES - CHECKSUMBYTES)
#define CHANNELS 6

/*
#define TESTCHANNEL 2
#define TESTCHANNELVALUE 2044
*/

static int running = 1;
static int firstPrint = 0;
static int extraLine = 0;

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
                        printf("Wrong checksum: %d != %d                    \n",
                               checksum, ((checksumData[0] << 8) | checksumData[1]));
                        extraLine++;
                        if (extraLine > 1) {
                            extraLine--;
                            printf("\r\033[1A");
                        }
                    } else {
                        // Decode channel values
                        uint16_t buff[CHANNELS + 1];
                        for (int i = 0; i < (CHANNELS + 1); i++) {
                            buff[i] = data[2 * i] << 8;
                            buff[i] |= data[(2 * i) + 1];
                        }

                        /*
                        // Check Test Channel Value (?)
                        if (buff[CHANNELS] != (TESTCHANNELVALUE - buff[TESTCHANNEL])) {
                            printf("Wrong test channel value: %d != %d (%d - %d)\n",
                                   buff[CHANNELS], TESTCHANNELVALUE - buff[TESTCHANNEL],
                                   TESTCHANNELVALUE, buff[TESTCHANNEL]);

                            printf("Correct would be: %d\n",
                                   buff[TESTCHANNEL] + buff[CHANNELS]);
                        }
                        */

                        if (firstPrint == 0) {
                            firstPrint = 1;
                        } else {
                            int num = CHANNELS + extraLine;
                            extraLine = 0;
                            for (int i = 0; i < num; i++) {
                                printf("\r\033[1A");
                            }
                        }

                        for (int i = 0; i < CHANNELS; i++) {
                            printf("CH%d: %d                    \n", i + 1, buff[i] - 1000);
                        }
                    }
                }
            }
        }

        usleep(1000);
    }

    serialClose(fd);

    return 0;
}

