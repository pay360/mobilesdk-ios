//
//  PPOBaseURLManager.m
//  Paypoint
//
//  Created by Robert Nash on 17/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOBaseURLManager.h"

@implementation PPOBaseURLManager

+(NSURL*)baseURLForEnvironment:(PPOEnvironment)environment {
    
    
    switch (environment) {
        case PPOEnvironmentSimulator:
            return [NSURL URLWithString:@"http://localhost:5000/mobileapi"];
            break;
            
        case PPOEnvironmentDevice:
            return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:5000/mobileapi", [PPOBaseURLManager laptopIP]]];
            break;
            
        default:
            return nil;
            break;
    }
    
}

@end
