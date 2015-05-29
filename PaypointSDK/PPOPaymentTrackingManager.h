//
//  PPOPaymentTrackingManager.h
//  Paypoint
//
//  Created by Robert Nash on 29/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    PAYMENT_STATE_NON_EXISTENT,
    PAYMENT_STATE_NOT_STARTED,
    PAYMENT_STATE_STARTING,
    PAYMENT_STATE_COMPLETE
} PAYMENT_STATE;

@class PPOPayment;
@interface PPOPaymentTrackingManager : NSObject

-(void)beginTrackingPayment:(PPOPayment*)payment withTimeout:(CGFloat)timeout;
-(void)endTrackingPayment:(PPOPayment*)payment;
-(PAYMENT_STATE)stateForPayment:(PPOPayment*)payment;
-(NSNumber*)hasPaymentTimedout:(PPOPayment*)payment;

@end
