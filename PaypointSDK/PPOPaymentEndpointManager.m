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
    return [baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"acceptor/rest/mobile/transactions/%@/payment", installationID]];
    
}

-(NSURL*)resumePaymentWithInstallationID:(NSString*)installationID transactionID:(NSString*)transID withBaseURL:(NSURL*)baseURL {
    return [baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"acceptor/rest/mobile/transactions/%@/%@/resume", transID, installationID]];
}

@end
