//
//  PPOPaymentManager.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOError.h"
#import "PPOPaymentValidator.h"

@class PPOTransaction;
@class PPOBillingAddress;

@interface PPOPaymentManager : PPOPaymentValidator

@property (nonatomic, strong, readonly) NSURL *baseURL;

-(instancetype)initWithBaseURL:(NSURL*)baseURL; //Designated initialiser

-(void)makePayment:(PPOPayment*)payment
   withCredentials:(PPOCredentials*)credentials
       withTimeOut:(CGFloat)timeout
    withCompletion:(void(^)(PPOOutcome *outcome, NSError *paymentFailure))completion;

@end
