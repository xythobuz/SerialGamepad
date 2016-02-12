# Mac OS X Gamepad Driver for Flysky compatible transmitters

This project emulates a virtual Gamepad using input data from a serial port. This can be used to enable Flysky CT6A / CT6B compatible transmitters (Turbobrix, Exceed, Modelcraft) in games or simulators.

####This software has been tested on the following versions of OS X: 
 * 10.10.x (Yosemite)
 * 10.11.x (El Capitan)

## Installation
### USB to Serial Driver
Depending on the USB-Serial cable included with your Transmitter, you may need to install the [SiLabs CP210x driver](https://www.silabs.com/products/mcu/Pages/USBtoUARTBridgeVCPDrivers.aspx).

You can verify that this is working by running the following command in a terminal:

`ls /dev/ | grep 'tty\.'`

You should see something that looks like `tty.SLAB_USBtoUART`. If you don't see something like that displayed, you either have an issue with the driver for your serial adapter (try reinstalling it) or you have a different serial adapter and you'll need to find the drivers for that. To see what adapter is registring with OS X, Apple => About This Mac => System Report => USB.

### Package File
Next you'll need to download and install the latest release of the Gamepad Driver (**includes foohid**) [here on GitHub](https://github.com/xythobuz/SerialGamepad/releases). 

_Note: You need to make sure to install the virtual userspace IOKit HID driver [foohid](https://github.com/unbit/foohid). This should be already be done if you install the .pkg_

## SerialGamepad GUI App

This app allows a compatible transmitter to connect over a serial port and then provide a virtual gamepad using fooHID. In the app, select your serial port from the dropdown list. (It should be the same one from the section above.) Next, click connect. If everything is working you should see the signals coming from the transmitter via the green bars. (See below) If it doesn't connect, make sure that you have your reciever turned on. 

![Screenshot](https://i.imgur.com/x0hnWq5.png)

_NOTE: Make sure to keep the SerialGamepad app running and connected when you start your simulator._

## foohid command-line app

This small utility does the same thing as the SerialGamepad.app without a graphical user interface.

## protocol command-line app

This small utility only reads the channel values from a serial port and pretty-prints them to a POSIX compatible terminal.

# For Developers

You don't need to use the included Makefile if you want to change something in the GUI App. Just directly open the XCode project file.

However, the makefile allows you not only to build the GUI app, but also a distributable Installer including the foohid dependency. For this, just run `make distribute`. The finished installer will be placed in `bin/SerialGamepad.pkg`.

To build the command-line apps and the GUI apps, just run `make all`. You can also install all of them using `sudo make install`. The cli-binaries will go to `/usr/local/bin`, the App to `/Applications`.

## Other Resources

 * [Serial protocol analysis](http://www.rcgroups.com/forums/showpost.php?p=11384029&postcount=79)
 * [T6config program informations](http://www.mycoolheli.com/t6config.html)
 * [T6config alternatives](http://www.mycoolheli.com/t6Alternate.html)
 * [Mac OS X version](http://www.zenoshrdlu.com/turborix/)

## Licensing

    ----------------------------------------------------------------------------
    "THE BEER-WARE LICENSE" (Revision 42):
    <xythobuz@xythobuz.de> wrote this file.  As long as you retain this notice
    you can do whatever you want with this stuff. If we meet some day, and you
    think this stuff is worth it, you can buy me a beer in return.   Thomas Buck
    ----------------------------------------------------------------------------

