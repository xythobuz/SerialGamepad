//
//  fooHID.h
//  SerialGamepad
//
//  Created by Thomas Buck on 14.12.15.
//  Copyright © 2015 xythobuz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface fooHID : NSObject

+ (NSInteger)init;
+ (void)close;
+ (void)send:(NSArray *)data;

@end
