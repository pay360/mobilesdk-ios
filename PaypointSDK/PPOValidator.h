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

/*!
 * @discussion Checks for the existence of a base URL.
 * @param baseURL The baseURL to be checked.
 * @return nil or an instance of NSError with the domain PPOPaypointSDKErrorDomain.
 */
+(NSError*)validateBaseURL:(NSURL*)baseURL;
+(NSError*)validatePayment:(PPOPayment*)payment;
+(NSError*)validateCredentials:(PPOCredentials*)credentials;
+(NSError*)validateTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card;
+(BOOL)baseURLInvalid:(NSURL*)url withCompletion:(void(^)(PPOOutcome *outcome, NSError *error))completion;
+(BOOL)credentialsInvalid:(PPOCredentials*)credentials withCompletion:(void(^)(PPOOutcome *outcome, NSError *error))completion;
+(BOOL)paymentInvalid:(PPOPayment*)payment withCompletion:(void(^)(PPOOutcome *outcome, NSError *error))completion;
+(BOOL)paymentUnderway:(PPOPayment*)payment withCompletion:(void(^)(PPOOutcome *outcome, NSError *error))completion;

@end
