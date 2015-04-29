//
//  PPOPaymentManager.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOError.h"
#import "PPOOutcome.h"
#import "PPOPaymentEndpointManager.h"

@class PPOPayment;
@class PPOCredentials;
@class PPOTransaction;
@class PPOBillingAddress;
@class PPOCreditCard;

@interface PPOPaymentManager : PPOPaymentEndpointManager

@property (nonatomic, strong, readonly) NSURL *baseURL;

-(instancetype)initWithBaseURL:(NSURL*)baseURL; //Designated initialiser

-(void)makePayment:(PPOPayment*)payment
   withCredentials:(PPOCredentials*)credentials
       withTimeOut:(CGFloat)timeout
    withCompletion:(void(^)(PPOOutcome *outcome, NSError *paymentFailure))completion;

@end

@interface PPOPaymentValidator : NSObject

+(NSError*)validateBaseURL:(NSURL*)baseURL;
+(NSError*)validatePayment:(PPOPayment*)payment;
+(NSError*)validateCredentials:(PPOCredentials*)credentials;
+(NSError*)validateTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card;
+(NSError*)validateCredentials:(PPOCredentials*)credentials validateBaseURL:(NSURL*)baseURL validatePayment:(PPOPayment*)payment;

@end