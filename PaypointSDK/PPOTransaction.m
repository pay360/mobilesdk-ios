//
//  PPOTransaction.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOTransaction.h"

@interface PPOTransaction ()
@property (nonatomic, strong, readwrite) NSString *currency;
@property (nonatomic, strong, readwrite) NSNumber *amount;
@property (nonatomic, strong, readwrite) NSString *transactionDescription;
@property (nonatomic, strong, readwrite) NSString *merchantRef;
@property (nonatomic, strong, readwrite) NSNumber *isDeferred;
@end

@implementation PPOTransaction

-(instancetype)initWithCurrency:(NSString*)currency withAmount:(NSNumber*)amount withDescription:(NSString*)description withMerchantReference:(NSString*)reference isDeferred:(BOOL)deferred {
    self = [super init];
    if (self) {
        _currency = currency;
        _amount = amount;
        _transactionDescription = description;
        _merchantRef = reference;
        _isDeferred = @(deferred);
    }
    return self;
}

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
