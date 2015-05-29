//
//  PPOEndpointManager.m
//  Paypoint
//
//  Created by Robert Nash on 20/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentEndpointManager.h"

@implementation PPOPaymentEndpointManager

-(NSURL*)urlForSimplePayment:(NSString*)installationID withBaseURL:(NSURL*)baseURL {
    return [baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"acceptor/rest/mobile/transactions/%@/payment", installationID]];
}

-(NSURL*)urlForPaymentWithID:(NSString*)paymentIdentifier withInst:(NSString*)installationID withBaseURL:(NSURL*)baseURL {
    return [baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"acceptor/rest/mobile/transactions/%@/opref/%@", installationID, paymentIdentifier]];
}

-(NSURL*)urlForResumePaymentWithInstallationID:(NSString*)installationID transactionID:(NSString*)transID withBaseURL:(NSURL*)baseURL {
    return [baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"acceptor/rest/mobile/transactions/%@/%@/resume", installationID, transID]];
}

@end
