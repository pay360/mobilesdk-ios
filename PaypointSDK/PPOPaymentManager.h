//
//  PPOPaymentManager.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPOCredentials;
@class PPOTransaction;
@class PPOCreditCard;
@class PPOBillingAddress;

@protocol PPOPaymentManagerDatasource <NSObject>
-(PPOCreditCard*)creditCard;
-(PPOBillingAddress*)billingAddress;
@end

@protocol PPOPaymentManagerDelegate <NSObject>
-(void)paymentSucceeded:(NSString*)feedback;
-(void)paymentFailed:(NSError*)error;
@end

@interface PPOPaymentManager : NSObject
@property (nonatomic, strong, readonly) NSOperationQueue *payments;
@property (nonatomic, strong) PPOCredentials *credentials;
@property (nonatomic, weak) id <PPOPaymentManagerDelegate> delegate;
@property (nonatomic, weak) id <PPOPaymentManagerDatasource> datasource;

-(instancetype)initWithCredentials:(PPOCredentials*)credentials withDelegate:(id<PPOPaymentManagerDelegate>)delegate; //Designated initialiser

-(void)startTransaction:(PPOTransaction*)transaction;

@end
