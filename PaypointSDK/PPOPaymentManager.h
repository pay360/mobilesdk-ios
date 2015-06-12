//
//  PPOPaymentManager.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOError.h"
#import "PPOOutcome.h"

@class PPOPayment;
@class PPOCredentials;
@class PPOTransaction;
@class PPOBillingAddress;
@class PPOCreditCard;

/**
 * @discussion A PPOPaymentManager object lets you make payments, with a convenient completion block callback. Each payment session can be configured with a time limit, which ensures the payment takes a limited time to complete.
 */
@interface PPOPaymentManager : NSObject

/*!
 * @discussion A required initialiser for setting the baseURL.
 * @param baseURL The base URL to be used for making payments. This may be for a test envirnoment, for example.
 * @return An instance of PPOPaymentManager
 */
-(instancetype)initWithBaseURL:(NSURL*)baseURL;

/*!
 * @discussion Makes a payment using the supplied information
 * @param payment Details of the payment.
 * @param timeout 60.0 seconds is the minimum recommended value, to ensure a payment has enough time to complete. Once this timeout expires, your payment session will terminate and the completion block will fire.
 * @param completion The outcome handler for the payment.
 */
-(void)makePayment:(PPOPayment*)payment
       withTimeOut:(NSTimeInterval)timeout
    withCompletion:(void(^)(PPOOutcome *outcome))completion;

/**
 *  Determines the current state of an existing payment.
 *  @param payment     Details of the payment.
 *  @param completion  The outcome handler for the payment.
 */
-(void)queryPayment:(PPOPayment*)payment
     withCompletion:(void(^)(PPOOutcome *outcome))completion;

/**
 *  Determines if a payment can be re-attempted without risk of a duplicate payment being made. If there is any chance of duplciation, this method returns NO.
 *  @param outcome The completion handler for the payment.
 *  @return A boolean indication that it is safe to re-attempt a payment, without risking a duplicate payment.
 */
+(BOOL)isSafeToRetryPaymentWithOutcome:(PPOOutcome*)outcome;

@end
