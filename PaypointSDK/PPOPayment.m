//
//  PPOPayment.m
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPayment.h"

@implementation PPOPayment

-(instancetype)initWithTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card withBillingAddress:(PPOBillingAddress*)address {
    self = [super init];
    if (self) {
        _transaction = transaction;
        _creditCard = card;
        _billingAddress = address;
    }
    return self;
}

@end
