//
//  PPOTransaction.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOTransaction.h"

@implementation PPOTransaction

-(NSDictionary*)jsonObjectRepresentation {
    id currency = (self.currency) ?: [NSNull null];
    id amount = (self.amount) ?: [NSNull null];
    id description = (self.transactionDescription) ?: [NSNull null];
    id reference = (self.merchantRef) ?: [NSNull null];
    id deferred = (self.isDeferred) ?: [NSNull null];
    
    return @{
             @"currency": currency,
             @"amount": amount,
             @"description": description,
             @"merchantRef": reference,
             @"deferred": deferred,
             };
}

@end
