//
//  PPOPaymentManager.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOCreditCard.h"
#import "PPOCredentials.h"
#import "PPOTransaction.h"
#import "PPOBillingAddress.h"

@interface PPOPaymentManager : NSObject

@property (nonatomic, strong, readonly) NSOperationQueue *payments;

-(instancetype)initWithCredentials:(PPOCredentials*)credentials; //Designated initialiser

-(void)startTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card forAddress:(PPOBillingAddress*)address completionHandler:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completion;

@end
