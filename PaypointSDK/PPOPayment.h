//
//  PPOPayment.h
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPOTransaction;
@class PPOBillingAddress;
@class PPOCreditCard;

@interface PPOPayment : NSObject

@property (nonatomic, strong) PPOTransaction *transaction;
@property (nonatomic, strong) PPOCreditCard *creditCard;
@property (nonatomic, strong) PPOBillingAddress *billingAddress;

-(instancetype)initWithTransaction:(PPOTransaction*)transaction
                          withCard:(PPOCreditCard*)card
                withBillingAddress:(PPOBillingAddress*)address;

@end
