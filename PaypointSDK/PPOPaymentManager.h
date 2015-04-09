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

@protocol PPOPaymentManagerDelegate <NSObject>
-(void)paymentSucceeded:(NSString*)feedback;
-(void)paymentFailed:(NSError*)error;
@end

@interface PPOPaymentManager : NSObject
@property (nonatomic, strong) PPOCredentials *credentials;
@property (nonatomic, weak) id <PPOPaymentManagerDelegate> delegate;

-(instancetype)initWithCredentials:(PPOCredentials*)credentials withDelegate:(id<PPOPaymentManagerDelegate>)delegate; //Designated initialiser

-(void)makePaymentWithTransaction:(PPOTransaction*)transaction forCard:(PPOCreditCard*)card withBillingAddress:(PPOBillingAddress*)billingAddress;

@end
