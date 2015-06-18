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
@class PPOCard;
@class PPOOutcome;

/*!
  @discussion A convenience class for validating several parameters.
 */
@interface PPOValidator : NSObject

/*!
   @discussion Validates the supplied base URL.
   @param baseURL The parameter to be validated.
   @return The error returned should be examined and cross-referenced with the error codes found within error domain PPOLocalValidationErrorDomain. See PPOError.h for details. Returns nil if the base URL is valid.
 */
+(NSError*)validateBaseURL:(NSURL*)baseURL;

/*!
   @discussion Validates the supplied credentials.
   @param credentials The parameter to be validated.
   @return The error returned should be examined and cross-referenced with the error codes found within error domain PPOLocalValidationErrorDomain. See PPOError.h for details. Returns nil if the credentials are valid.
 */
+(NSError*)validateCredentials:(PPOCredentials*)credentials;

/*!
   @discussion Validates the supplied payment.
   @param payment The parameter to be validated.
   @return The error returned should be examined and cross-referenced with the error codes found within error domain PPOLocalValidationErrorDomain. See PPOError.h for details. Returns nil if the payment is valid.
 */
+(NSError*)validatePayment:(PPOPayment*)payment;

/*!
   @discussion Validates the supplied card.
   @param card The parameter to be validated.
   @return The error returned should be examined and cross-referenced with the error codes found within error domain PPOLocalValidationErrorDomain. See PPOError.h for details. Returns nil if the card is valid.
 */
+(NSError*)validateCard:(PPOCard*)card;

/*!
   @discussion Validates the supplied pan.
   @param pan The parameter to be validated.
   @return The error returned should be examined and cross-referenced with the error codes found within error domain PPOLocalValidationErrorDomain. See PPOError.h for details. Returns nil if the pan is valid.
 */
+(NSError*)validateCardPan:(NSString*)pan;

/*!
   @discussion Validates the supplied expiry.
   @param expiry The parameter to be validated.
   @return The error returned should be examined and cross-referenced with the error codes found within error domain PPOLocalValidationErrorDomain. See PPOError.h for details. Returns nil if the expiry is valid.
 */
+(NSError*)validateCardExpiry:(NSString*)expiry;

/*!
   @discussion Validates the supplied cvv.
   @param cvv The parameter to be validated.
   @return The error returned should be examined and cross-referenced with the error codes found within error domain PPOLocalValidationErrorDomain. See PPOError.h for details. Returns nil if the cvv is valid.
 */
+(NSError*)validateCardCVV:(NSString*)cvv;

/*!
   @discussion Validates the supplied transaction.
   @param transaction The parameter to be validated.
   @return The error returned should be examined and cross-referenced with the error codes found within error domain PPOLocalValidationErrorDomain. See PPOError.h for details. Returns nil if the transaction is valid.
 */
+(NSError*)validateTransaction:(PPOTransaction*)transaction;

/*!
   @discussion Validates the supplied currency.
   @param currency The parameter to be validated.
   @return The error returned should be examined and cross-referenced with the error codes found within error domain PPOLocalValidationErrorDomain. See PPOError.h for details. Returns nil if the currency is valid.
 */
+(NSError*)validateCurrency:(NSString*)currency;

/*!
   @dicsussion Validates the supplied amount.
   @param amount The parameter to be validated.
   @return The error returned should be examined and cross-referenced with the error codes found within error domain PPOLocalValidationErrorDomain. See PPOError.h for details. Returns nil if the amount is valid.
 */
+(NSError*)validateAmount:(NSNumber*)amount;

@end
