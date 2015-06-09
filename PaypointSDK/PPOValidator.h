//
//  PPOPaymentValidator.h
//  Paypoint
//
//  Created by Robert Nash on 01/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPOPayment;
@class PPOCredentials;
@class PPOTransaction;
@class PPOCreditCard;
@class PPOOutcome;
@interface PPOValidator : NSObject

//Network
+(NSError*)validateBaseURL:(NSURL*)baseURL;
+(NSError*)validateCredentials:(PPOCredentials*)credentials;

//Payment
+(NSError*)validatePayment:(PPOPayment*)payment;

//Card
+(NSError*)validateCard:(PPOCreditCard*)card;
+(NSError*)validateCardPan:(NSString*)pan;
+(NSError*)validateCardExpiry:(NSString*)expiry;
+(NSError*)validateCardCVV:(NSString*)cvv;

//Transaction
+(NSError*)validateTransaction:(PPOTransaction*)transaction;
+(NSError*)validateCurrency:(NSString*)currency;
+(NSError*)validateAmount:(NSNumber*)amount;

@end
