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
#import "PPOFinancialService.h"
#import "PPOCustomer.h"

/**
 * @discussion A PPOPayment object represents a payment.
 */
@interface PPOPayment : NSObject
@property (nonatomic, strong) PPOTransaction *transaction;
@property (nonatomic, strong) PPOCreditCard *card;
@property (nonatomic, strong) PPOBillingAddress *address;
@property (nonatomic, strong) PPOFinancialService *financialServices;
@property (nonatomic, strong) PPOCustomer *customer;
@property (nonatomic, strong) PPOCredentials *credentials;
@property (nonatomic, strong) NSSet *customFields;

/**
 *  A unique identifier for traceability.
 */
@property (nonatomic, readonly, copy) NSString *identifier;
@end
