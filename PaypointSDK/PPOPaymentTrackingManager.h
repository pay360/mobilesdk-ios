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
    PAYMENT_STATE_READY,
    PAYMENT_STATE_IN_PROGRESS,
    PAYMENT_STATE_SUSPENDED //For events like three d secure && user input required
} PAYMENT_STATE;

@class PPOPayment;
@class PPOOutcome;
@interface PPOPaymentTrackingManager : NSObject
+(void)appendPayment:(PPOPayment*)payment withTimeout:(NSTimeInterval)timeout commenceTimeoutImmediately:(BOOL)begin timeoutHandler:(void(^)(void))handler;
+(void)removePayment:(PPOPayment*)payment;
+(void)resumeTimeoutForPayment:(PPOPayment*)payment;
+(void)suspendTimeoutForPayment:(PPOPayment*)payment;
+(PAYMENT_STATE)stateForPayment:(PPOPayment*)payment;
+(NSNumber*)hasPaymentSessionTimedoutForPayment:(PPOPayment*)payment;
+(NSNumber*)remainingSessionTimeoutForPayment:(PPOPayment*)payment;
+(void)setTimeoutHandler:(void(^)(void))handler forPayment:(PPOPayment*)payment;
+(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandlerForPayment:(PPOPayment *)payment;
+(BOOL)allPaymentsComplete;
+(void)logIsQueryingStatusOfPayment:(PPOPayment*)payment;
+(void)logIsNotQueryingStatusOfPayment:(PPOPayment*)payment;
+(BOOL)isQueryingStatusOfPayment:(PPOPayment*)payment;
+(NSUInteger)currentTrackCount;
@end
