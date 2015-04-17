//
//  PPOBaseURLManager.m
//  Paypoint
//
//  Created by Robert Nash on 17/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOBaseURLManager.h"

@implementation PPOBaseURLManager

+(NSURL*)baseURL:(PPOEnvironment)environment {
    
    switch (environment) {
        case PPOEnvironmentStaging:
            return [NSURL URLWithString:@"http://localhost:5000/mobileapi"];
            break;
            
        case PPOEnvironmentProduction:
            return [NSURL URLWithString:@"http://192.168.3.192:5000/mobileapi"];
            break;
            
        default:
            return nil;
            break;
    }
    
}

@end
