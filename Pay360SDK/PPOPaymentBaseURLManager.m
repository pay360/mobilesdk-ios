//
//  PPOPaymentBaseURLManager.m
//  Pay360
//
//  Created by Robert Nash on 17/04/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import "PPOPaymentBaseURLManager.h"

@implementation PPOPaymentBaseURLManager

+(NSURL*)baseURLForEnvironment:(PPOEnvironment)environment {
    
    switch (environment) {
        case PPOEnvironmentMerchantIntegrationTestingEnvironment:
            return [NSURL URLWithString:@"https://mobileapi.mite.pay360.com"];
            break;
            
        case PPOEnvironmentMerchantIntegrationProductionEnvironment:
            return [NSURL URLWithString:@"https://mobileapi.pay360.com"];
            break;
            
        default:
            return nil;
            break;
    }
    
}

@end
