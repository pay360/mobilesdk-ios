//
//  PPOPaymentValidator.h
//  Paypoint
//
//  Created by Robert Nash on 20/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOOutcome.h"
#import "PPOPaymentEndpointManager.h"
#import "PPOTransaction.h"
#import "PPOCredentials.h"
#import "PPOCreditCard.h"

@class PPOPayment;

@interface PPOPaymentValidator : PPOPaymentEndpointManager

-(NSError*)validateBaseURL:(NSURL*)baseURL;
-(NSError*)validatePayment:(PPOPayment*)payment;
-(NSError*)validateCredentials:(PPOCredentials*)credentials;
-(NSError*)validateTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card;
-(NSError*)validateCredentials:(PPOCredentials*)credentials validateBaseURL:(NSURL*)baseURL validatePayment:(PPOPayment*)payment;

@end
