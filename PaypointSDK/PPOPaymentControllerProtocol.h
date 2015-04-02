//
//  PaymentControllerDelegate.h
//  Paypoint
//
//  Created by Robert Nash on 23/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOErrorController.h"

@class PPOPaymentForm;
@protocol PPOPaymentControllerProtocol <NSObject>

-(void)userCancelledCardFormEntry;
//-(void)userCompletedCardFormEntry:(NSError*)error;
-(void)userCompletedCardFormEntry:(NSString*)message;

@end
