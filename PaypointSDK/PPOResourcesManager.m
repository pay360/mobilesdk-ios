//
//  PPOResourcesManager.m
//  Paypoint
//
//  Created by Robert Nash on 12/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOResourcesManager.h"

@implementation PPOResourcesManager

+(NSBundle*)resources {
    NSString *resourceBundlePath = [[NSBundle mainBundle] pathForResource:@"PaypointResources" ofType:@"bundle"];
    return [NSBundle bundleWithPath:resourceBundlePath];
}

+(NSDictionary*)info {
    NSString *path = [[PPOResourcesManager resources] pathForResource:@"Info" ofType:@"plist"];
    return [NSDictionary dictionaryWithContentsOfFile:path];
}

+(NSDictionary*)frameworkVersion {
    NSString *version = [[PPOResourcesManager info] objectForKey:@"CFBundleShortVersionString"];
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
    NSString *version = [[PPOResourcesManager info] objectForKey:@"DYLIB_CURRENT_VERSION"];
    return @(version.doubleValue);
}

@end
