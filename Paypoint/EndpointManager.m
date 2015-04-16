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
        case PPOEnvironmentStaging:
            return [NSURL URLWithString:@"http://localhost:5001"];
            break;
            
        case PPOEnvironmentProduction:
            return [NSURL URLWithString:@"http://192.168.3.192:5001"];
            break;
            
        default:
            return nil;
            break;
    }
    
}

@end
