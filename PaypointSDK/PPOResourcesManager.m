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

+(NSDictionary*)frameworkVersion {
    NSString *path = [[PPOResourcesManager resources] pathForResource:@"Info" ofType:@"plist"];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
    NSString *version = [plist objectForKey:@"CFBundleShortVersionString"];
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

@end
