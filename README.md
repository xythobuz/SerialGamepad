# Mac OS X Gamepad Driver for Flysky compatible transmitters

This project emulates a virtual Gamepad using input data from a serial port. This can be used to enable Flysky CT6A / CT6B compatible transmitters (Turbobrix, Exceed, Modelcraft) in games or simulators.

**You need to install the virtual userspace IOKit HID driver *foohid*:**

[GitHub page](https://github.com/unbit/foohid), [Binary releases](https://github.com/unbit/foohid/releases).

## SerialGamepad GUI App

This app can connect to a compatible transmitter over a serial port and then provide a virtual gamepad using fooHID.

![Screenshot](https://i.imgur.com/x0hnWq5.png)

## foohid command-line app

This small utility does the same thing as the SerialGamepad.app without a graphical user interface.

## protocol command-line app

This small utility only reads the channel values from a serial port and pretty-prints them to a POSIX compatible terminal.

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

