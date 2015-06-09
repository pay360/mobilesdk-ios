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
    PAYMENT_STATE_SUSPENDED //We pause the session timeout timer, whilst three d secure is on screen and asking for user input.
} PAYMENT_STATE;

@class PPOPayment;
@class PPOOutcome;
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
+(NSUInteger)totalRecursiveQueryPaymentAttemptsForPayment:(PPOPayment*)payment;
+(void)incrementRecurisiveQueryPaymentAttemptCountForPayment:(PPOPayment*)payment;
+(void(^)(void))timeoutHandlerForPayment:(PPOPayment*)payment;
+(NSTimeInterval)timeIntervalForAttemptCount:(NSUInteger)attempt;

@end
