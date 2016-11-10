//
//  PPOPaymentTrackingManager.h
//  Pay360
//
//  Created by Robert Nash on 29/05/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPOPaymentReference.h"
#import <objc/runtime.h>

typedef enum : NSUInteger {
    PAYMENT_STATE_NON_EXISTENT,
    PAYMENT_STATE_READY,
    PAYMENT_STATE_IN_PROGRESS,
    PAYMENT_STATE_SUSPENDED //We pause the session timeout timer, whilst three d secure is on screen and asking for user input.
} PAYMENT_STATE;

@class PPOPayment;
@class PPOOutcome;

/*!
 *  This class is not thread safe.
 */
@interface PPOPaymentTrackingManager : NSObject

+(void)appendPayment:(PPOPayment*)payment
         withTimeout:(NSTimeInterval)timeout
        beginTimeout:(BOOL)begin
      timeoutHandler:(void(^)(void))handler;

+(void)removePayment:(PPOPayment*)payment;
+(void)resumeTimeoutForPayment:(PPOPayment*)payment;
+(void)suspendTimeoutForPayment:(PPOPayment*)payment;
+(PAYMENT_STATE)stateForPayment:(PPOPayment*)payment;
+(void)overrideTimeoutHandler:(void(^)(void))handler forPayment:(PPOPayment*)payment;
+(BOOL)masterSessionTimeoutHasExpiredForPayment:(PPOPayment*)payment;
+(BOOL)allPaymentsComplete;
+(BOOL)paymentIsBeingTracked:(PPOPayment*)payment;
+(NSUInteger)totalQueryPaymentAttemptsForPayment:(PPOPayment*)payment;
+(void)incrementQueryPaymentAttemptCountForPayment:(PPOPayment*)payment;
+(void(^)(void))timeoutHandlerForPayment:(PPOPayment*)payment;
+(NSTimeInterval)timeIntervalForAttemptCount:(NSUInteger)attempt;

@end
