//
//  PPOPaymentManager.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOError.h"
#import "PPOOutcome.h"

@class PPOCredentials;
@class PPOTransaction;
@class PPOCreditCard;
@class PPOBillingAddress;
@class PPOPayment;

typedef NS_ENUM(NSInteger, PPOEnvironment) {
    PPOEnvironmentSimulatorStaging,
    PPOEnvironmentDeviceStaging
};

@interface PPOPaymentManager : NSObject
@property (nonatomic, strong) PPOCredentials *credentials;
@property (nonatomic, readonly) PPOEnvironment currentEnivonrment;

-(instancetype)initForEnvironment:(PPOEnvironment)environment; //Designated initialiser

-(void)makePayment:(PPOPayment*)payment withTimeOut:(CGFloat)timeout withCompletion:(void(^)(PPOOutcome *outcome))completion;

@end
