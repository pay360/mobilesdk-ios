//
//  EndpointManager.m
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "EndpointManager.h"

@implementation EndpointManager

+(NSURL*)baseURL:(PPOEnvironment)environment {
    
    switch (environment) {
        case PPOEnvironmentSimulator:
            return [NSURL URLWithString:@"http://localhost:5001"];
            break;
            
        case PPOEnvironmentDevice:
            return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:5001", [EndpointManager laptopIP]]];
            break;
            
        default:
            return nil;
            break;
    }
    
}

+(NSString*)laptopIP {
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    NSString *value = [environment objectForKey:@"LAPTOP_IP"];
    return value;
}

@end
