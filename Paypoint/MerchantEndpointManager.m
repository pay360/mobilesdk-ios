//
//  EndpointManager.m
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "MerchantEndpointManager.h"

@implementation MerchantEndpointManager

+(NSURL*)baseURL:(PPOEnvironment)environment {
    
    switch (environment) {
        case PPOEnvironmentStaging:
            return [NSURL URLWithString:[NSString stringWithFormat:@"http://192.168.3.243:5001"]];
            break;
            
        default:
            return nil;
            break;
    }
    
}

@end
