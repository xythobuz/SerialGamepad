# Mac OS X Gamepad Driver for Flysky compatible transmitters

This project emulates a virtual Gamepad using input data from a serial port. This can be used to enable Flysky CT6A / CT6B compatible transmitters (Turbobrix, Exceed, Modelcraft) in games or simulators.

Depending on the USB-Serial converter stick included with your Transmitter, you may need to install the [SiLabs CP210x driver](https://www.silabs.com/products/mcu/Pages/USBtoUARTBridgeVCPDrivers.aspx).

You also need to install the virtual userspace IOKit HID driver [foohid](https://github.com/unbit/foohid).

Download the latest release (**already including foohid**) [here on GitHub](https://github.com/xythobuz/SerialGamepad/releases).

This software has been tested on OS 10.10 (Yosemite) and 10.11 (El Capitan).

## SerialGamepad GUI App

This app can connect to a compatible transmitter over a serial port and then provide a virtual gamepad using fooHID.

![Screenshot](https://i.imgur.com/x0hnWq5.png)

First, press `Connect` to establish a connection to your Transmitter. As soon as it is working the current stick positions will be visualized. Then, press `Create` to create a virtual HID Gamepad.

As long as both have been initialized, you can use your Transmitter in your Simulator. The connection will be closed and the virtual device destroyed automatically when you close the App window.

## foohid command-line app

This small utility does the same thing as the SerialGamepad.app without a graphical user interface.

## protocol command-line app

This small utility only reads the channel values from a serial port and pretty-prints them to a POSIX compatible terminal.

# For Developers

You don’t need to use the included Makefile if you want to change something in the GUI App. Just directly open the XCode project file.

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

