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
        case PPOEnvironmentStaging:
            return [NSURL URLWithString:[NSString stringWithFormat:@"http://192.168.3.243:5000/mobileapi"]];
            break;
            
        default:
            return nil;
            break;
    }
    
}

@end