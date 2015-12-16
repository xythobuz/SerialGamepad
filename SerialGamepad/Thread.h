//
//  Thread.h
//  SerialGamepad
//
//  Created by Thomas Buck on 15.12.15.
//  Copyright © 2015 xythobuz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MainWindow;

@interface Thread : NSThread

@property BOOL running;
@property int fd;
@property (strong) NSString *portName;
@property (weak) MainWindow *mainWindow;

- (id)initWithWindow:(MainWindow *)window;
- (NSInteger)openPort;

@end
