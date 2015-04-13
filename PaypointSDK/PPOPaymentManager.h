//
//  PPOPaymentManager.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOError.h"

@class PPOCredentials;
@class PPOTransaction;
@class PPOCreditCard;
@class PPOBillingAddress;

typedef NS_ENUM(NSInteger, PPOEnvironment) {
    PPOEnvironmentStaging
};

@interface PPOPaymentManager : NSObject
@property (nonatomic, strong) PPOCredentials *credentials;
@property (nonatomic, readonly) PPOEnvironment currentEnivonrment;

-(instancetype)initForEnvironment:(PPOEnvironment)environment; //Designated initialiser

-(void)makePaymentWithTransaction:(PPOTransaction*)transaction forCard:(PPOCreditCard*)card withBillingAddress:(PPOBillingAddress*)billingAddress withTimeOut:(CGFloat)timeout withCompletion:(void(^)(NSError *error, NSString *message))completion;

@end
