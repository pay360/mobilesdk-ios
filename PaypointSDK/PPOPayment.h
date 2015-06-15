//
//  PPOPayment.h
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOTransaction.h"
#import "PPOBillingAddress.h"
#import "PPOCreditCard.h"
#import "PPOCredentials.h"
#import "PPOFinancialServices.h"
#import "PPOCustomer.h"

/**
 *  A PPOPayment object represents a payment. Each instance of this class generates it's own unique identifier, for traceability during and after a payment is processed.
 */
@interface PPOPayment : NSObject
@property (nonatomic, strong) PPOTransaction *transaction;
@property (nonatomic, strong) PPOCreditCard *card;
@property (nonatomic, strong) PPOBillingAddress *address;
@property (nonatomic, strong) PPOFinancialServices *financialServices;
@property (nonatomic, strong) PPOCustomer *customer;
@property (nonatomic, strong) PPOCredentials *credentials;
@property (nonatomic, strong) NSSet *customFields;
@property (nonatomic, readonly, copy) NSString *identifier;
@end
