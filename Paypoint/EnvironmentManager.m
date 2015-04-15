//
//  EnvironmentManager.m
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "EnvironmentManager.h"

@implementation EnvironmentManager

+(NSUInteger)currentEnvironment {
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    NSString *value = [environment objectForKey:@"ENVIRONMENT"];
    return value.integerValue;
}

@end
