//
//  PPOPaymentManager.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOError.h"
#import "PPOOutcome.h"
#import "PPOBaseURLManager.h"

@class PPOCredentials;
@class PPOTransaction;
@class PPOCreditCard;
@class PPOBillingAddress;
@class PPOPayment;

@interface PPOPaymentManager : PPOBaseURLManager

@property (nonatomic, strong) NSOperationQueue *payments;
@property (nonatomic, strong, readonly) NSURL *baseURL;

-(instancetype)initWithBaseURL:(NSURL*)baseURL; //Designated initialiser
-(PPOOutcome*)validatePayment:(PPOPayment*)payment;
-(PPOOutcome*)validateCredentials:(PPOCredentials*)credentials;

-(void)makePayment:(PPOPayment*)payment
   withCredentials:(PPOCredentials*)credentials
       withTimeOut:(CGFloat)timeout
    withCompletion:(void(^)(PPOOutcome *outcome))completion;

@end
