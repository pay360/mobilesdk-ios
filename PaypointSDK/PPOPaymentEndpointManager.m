//
//  PPOEndpointManager.m
//  Pay360
//
//  Created by Robert Nash on 20/04/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import "PPOPaymentEndpointManager.h"

@interface PPOPaymentEndpointManager ()
@property (nonatomic, strong, readwrite) NSURL *baseURL;
@end

@implementation PPOPaymentEndpointManager

-(instancetype)initWithBaseURL:(NSURL*)baseURL {
    self = [super init];
    if (self) {
        _baseURL = baseURL;
    }
    return self;
}

-(NSURL*)urlForSimplePayment:(NSString*)installationID {
    return [self.baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"acceptor/rest/mobile/transactions/%@/payment", installationID]];
}

-(NSURL*)urlForPaymentWithID:(NSString*)paymentIdentifier withInst:(NSString*)installationID {
    return [self.baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"acceptor/rest/mobile/transactions/%@/opref/%@", installationID, paymentIdentifier]];
}

-(NSURL*)urlForResumePaymentWithInstallationID:(NSString*)installationID transactionID:(NSString*)transID {
    return [self.baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"acceptor/rest/mobile/transactions/%@/%@/resume", installationID, transID]];
}

@end
