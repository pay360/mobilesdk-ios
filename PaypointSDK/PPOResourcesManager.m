//
//  PPOResourcesManager.m
//  Pay360
//
//  Created by Robert Nash on 12/05/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import "PPOResourcesManager.h"

@implementation PPOResourcesManager

+(NSBundle*)resources {
    NSString *resourceBundlePath = [[NSBundle mainBundle] pathForResource:@"PayPointPayments" ofType:@"bundle"];
    return [NSBundle bundleWithPath:resourceBundlePath];
}

+(NSDictionary*)infoPlist {
    NSString *path = [[PPOResourcesManager resources] pathForResource:@"Info" ofType:@"plist"];
    return [NSDictionary dictionaryWithContentsOfFile:path];
}

+(NSDictionary*)frameworkVersion {
    NSString *version = [[PPOResourcesManager infoPlist] objectForKey:@"CFBundleShortVersionString"];
    NSArray *components = [version componentsSeparatedByString:@"."];
    NSUInteger counter = 0;
    NSMutableDictionary *collector = [NSMutableDictionary new];
    for (NSString *component in components) {
        switch (counter) {
                
            case 0:
                [collector setObject:@(component.doubleValue) forKey:@"Major"];
                break;
                
            case 1:
                [collector setObject:@(component.doubleValue) forKey:@"Point"];
                break;
                
            case 2:
                [collector setObject:@(component.doubleValue) forKey:@"Minor"];
                break;
                
            default:
                break;
        }
        counter++;
    }
    
    return [collector copy];
}

//Read note under Step 2 here https://developer.apple.com/library/ios/qa/qa1827/_index.html

+(NSNumber*)frameworkBuild {
    NSString *version = [[PPOResourcesManager infoPlist] objectForKey:@"DYLIB_CURRENT_VERSION"];
    return @(version.doubleValue);
}

@end
