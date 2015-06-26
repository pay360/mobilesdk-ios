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
    id recurring = (self.isRecurring) ?: [NSNull null];
    
    NSNumber *isDeferred = deferred;
    
    if ([isDeferred isKindOfClass:[NSNumber class]] && isDeferred.integerValue > 1) {
        isDeferred = @NO;
    }
    
    NSNumber *isRecurring = recurring;
    
    if ([isRecurring isKindOfClass:[NSNumber class]] && isRecurring.integerValue > 1) {
        isRecurring = @NO;
    }
    
    NSMutableDictionary *collector = [@{
                                       @"currency": currency,
                                       @"amount": amount,
                                       @"description": description,
                                       @"merchantRef": reference
                                       } mutableCopy];
    
    if ([isDeferred isKindOfClass:[NSNumber class]]) {
        [collector setValue:isDeferred forKey:@"deferred"];
    }
    
    if ([isRecurring isKindOfClass:[NSNumber class]]) {
        [collector setValue:isRecurring forKey:@"recurring"];
    }
    
    return [collector copy];
}

@end
