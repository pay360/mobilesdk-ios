//
//  PPOPaymentBaseURLManager.m
//  Paypoint
//
//  Created by Robert Nash on 17/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentBaseURLManager.h"

@implementation PPOPaymentBaseURLManager

+(NSURL*)baseURLForEnvironment:(PPOEnvironment)environment {
    
    switch (environment) {
        case PPOMerchantIntegrationTestingEnvironment:
            return [NSURL URLWithString:@"https://ppmobilesdkstub.herokuapp.com/mobileapi"];
            break;
            
        default:
            return nil;
            break;
    }
    
}

@end
