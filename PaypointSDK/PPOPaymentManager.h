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

@interface PPOPaymentManager : NSObject

/*!
 * @discussion A required initialiser for setting the baseURL.
 * @param baseURL The baseURL to be used for all subsequent payments made using an instance of this class.
 * @return An instance of PPOPaymentManager
 */
-(instancetype)initWithBaseURL:(NSURL*)baseURL;

/*!
 * @discussion Makes a payment using the supplied information
 * @param payment Details of the payment.
 * @param timeout 60.0 seconds is the minimum recommended, to lower the risk of failed payments.
 * @param completion The outcome handler for the payment. Inspect the completion block error domain PPOPaypointSDKErrorDomain for paypoint specific error cases. Each error code can be found within PPOError.h
 */
-(void)makePayment:(PPOPayment*)payment
       withTimeOut:(NSTimeInterval)timeout
    withCompletion:(void(^)(PPOOutcome *outcome))completion;

/**
 *  Determines the outcome of an existing payment. If a payment is currently in progress or suspended, 'outcome' will be nil and an error description returned.
 *
 *  @param payment     Details of the payment.
 *  @param completion  The outcome handler for the payment. Inspect the error domain PPOPaypointSDKErrorDomain for paypoint specific error cases. Each error code can be found within PPOError.h
 */
-(void)queryPayment:(PPOPayment*)payment
     withCompletion:(void(^)(PPOOutcome *outcome))completion;

@end
