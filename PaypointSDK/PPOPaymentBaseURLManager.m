//
//  PPOPaymentBaseURLManager.m
//  Pay360
//
//  Created by Robert Nash on 17/04/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import "PPOPaymentBaseURLManager.h"

@implementation PPOPaymentBaseURLManager

+(NSURL*)baseURLForEnvironment:(PPOEnvironment)environment {
    
    switch (environment) {
        case PPOEnvironmentMerchantIntegrationTestingEnvironment:
            return [NSURL URLWithString:@"https://api.mite.paypoint.net:2443"];
            break;
            
        case PPOEnvironmentMerchantIntegrationProductionEnvironment:
            return [NSURL URLWithString:@"https://api.paypoint.net"];
            break;
            
        default:
            return nil;
            break;
    }
    
}

@end
