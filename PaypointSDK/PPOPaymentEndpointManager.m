//
//  PPOEndpointManager.m
//  Paypoint
//
//  Created by Robert Nash on 20/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentEndpointManager.h"

@implementation PPOPaymentEndpointManager

-(NSURL*)simplePayment:(NSString*)installationID withBaseURL:(NSURL*)baseURL {
    return [baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"/transactions/%@/payment", installationID]];
    
}

@end
