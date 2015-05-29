//
//  PPOPayment.h
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPOTransaction;
@class PPOBillingAddress;
@class PPOCreditCard;
@class PPOFinancialServices;
@class PPOCustomer;
@interface PPOPayment : NSObject
@property (nonatomic, strong) PPOTransaction *transaction;
@property (nonatomic, strong) PPOCreditCard *card;
@property (nonatomic, strong) PPOBillingAddress *address;
@property (nonatomic, strong) PPOFinancialServices *financialServices;
@property (nonatomic, strong) PPOCustomer *customer;
@property (nonatomic, strong) NSSet *customFields;
@property (nonatomic, readonly, copy) NSString *identifier;
@end
