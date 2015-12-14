//
//  Serial.h
//  SerialGamepad
//
//  Created by Thomas Buck on 14.12.15.
//  Copyright © 2015 xythobuz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Serial : NSObject

+ (NSArray *)listSerialPorts;

@end

// Internal
kern_return_t findSerialPorts(io_iterator_t *matches);
kern_return_t getSerialPortPath(io_iterator_t serialPortIterator, char **deviceFilePath, CFIndex maxPathCount, CFIndex maxPathSize);
