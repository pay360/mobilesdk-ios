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
-(void)appendPayment:(PPOPayment*)payment withTimeout:(NSTimeInterval)timeout commenceTimeoutImmediately:(BOOL)begin;
-(void)removePayment:(PPOPayment*)payment;
-(void)resumeTimeoutForPayment:(PPOPayment*)payment;
-(void)stopTimeoutForPayment:(PPOPayment*)payment;
-(PAYMENT_STATE)stateForPayment:(PPOPayment*)payment;
-(NSNumber*)hasPaymentSessionTimedoutForPayment:(PPOPayment*)payment;
@end
