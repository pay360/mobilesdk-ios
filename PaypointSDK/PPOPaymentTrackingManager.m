//
//  PPOPaymentTrackingManager.m
//  Paypoint
//
//  Created by Robert Nash on 29/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentTrackingManager.h"
#import "PPOPayment.h"
#import "PPOSDKConstants.h"

@interface PPOPaymentTrackingChapperone : NSObject
//The payment is weak here. So if no other object is holding it, we don't need to track it.
@property (nonatomic, readonly, weak) PPOPayment *payment;
@property (nonatomic, readonly) NSTimeInterval sessionTimeout;
@property (nonatomic) NSUInteger queryPaymentCount;
@property (nonatomic) PAYMENT_STATE state;
-(instancetype)initWithPayment:(PPOPayment *)payment withTimeout:(NSTimeInterval)timeout timeoutHandler:(void(^)(void))timeoutHandler;
-(void)startTimeoutTimer;
-(void)stopTimeoutTimer;
-(BOOL)masterSessionTimeoutHasExpired;
@end

@interface PPOPaymentTrackingChapperone ()
@property (nonatomic, readwrite) NSTimeInterval sessionTimeout;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) void(^timeoutHandler)(void);
@end

@implementation PPOPaymentTrackingChapperone

-(instancetype)initWithPayment:(PPOPayment *)payment withTimeout:(NSTimeInterval)timeout timeoutHandler:(void(^)(void))timeoutHandler {
    self = [super init];
    if (self) {
        _payment = payment;
        _state = PAYMENT_STATE_READY;
        if (timeout < 0.0f) {
            timeout = 0;
        }
        _sessionTimeout = timeout;
        _timeoutHandler = timeoutHandler;
    }
    return self;
}

-(BOOL)isEqual:(id)object {
    PPOPaymentTrackingChapperone *chapperone;
    if ([object isKindOfClass:[PPOPaymentTrackingChapperone class]]) {
        chapperone = chapperone;
    }
    return (chapperone && [self.payment isEqual:chapperone.payment]);
}

-(void)startTimeoutTimer {
    
    if (self.sessionTimeout >= 0 && !self.timer) {
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(timeoutTimerFired:)
                                                    userInfo:nil
                                                     repeats:YES];
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Resuming implementing developers timeout for payment with op ref: %@", self.payment.identifier);
        }
    }
    
}

-(void)stopTimeoutTimer {
    
    if (PPO_DEBUG_MODE && self.timer && [self.timer isValid] && self.sessionTimeout > 0) {
        NSLog(@"Stopping implementing developers timeout for payment with op ref: %@ with remaining time: %f", self.payment.identifier, self.sessionTimeout);
    }
    
    [self.timer invalidate];
    self.timer = nil;
}

-(void)timeoutTimerFired:(NSTimer*)timer {
    
    if (timer.isValid) {
        
        if (PPO_DEBUG_MODE) {
            NSString *message = (self.sessionTimeout == 1) ? @"second" : @"seconds";
            NSLog(@"Implementing developers timeout is %f %@ for payment with op ref %@", self.sessionTimeout, message, self.payment.identifier);
        }
        
        if (self.sessionTimeout <= 0) {
            
            [PPOPaymentTrackingManager removePayment:self.payment];
            
            if (PPO_DEBUG_MODE) {
                NSLog(@"Implementing developers timeout has fired");
                NSLog(@"Implementing developers timeout is '0'");
                NSLog(@"Performing currently assigned abort sequence");
            }
            
            self.timeoutHandler();
        } else {
            self.sessionTimeout--;
        }
    }
    
}

-(BOOL)masterSessionTimeoutHasExpired {
    return self.sessionTimeout <= 0;
}

@end

@interface PPOPaymentTrackingManager ()
@property (nonatomic, strong) NSMutableSet *paymentChapperones;
@property (nonatomic, strong) NSArray *queryPaymentTimeIntervals;
@end

@implementation PPOPaymentTrackingManager

//A singleton is used privately, to prevent tracking manager duplication.
+(instancetype)sharedManager {
    static id sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}

-(NSMutableSet *)paymentChapperones {
    if (_paymentChapperones == nil) {
        _paymentChapperones = [NSMutableSet new];
    }
    return _paymentChapperones;
}

-(NSArray *)queryPaymentTimeIntervals {
    if (_queryPaymentTimeIntervals == nil) {
        _queryPaymentTimeIntervals = @[@(1), @(2), @(2), @(5)];
    }
    return _queryPaymentTimeIntervals;
}

+(void)appendPayment:(PPOPayment*)payment
         withTimeout:(NSTimeInterval)timeout
        beginTimeout:(BOOL)begin
      timeoutHandler:(void(^)(void))handler {
    
    if (!payment) {
        return;
    }
    
    PPOPaymentTrackingChapperone *chapperone = [[PPOPaymentTrackingChapperone alloc] initWithPayment:payment
                                                                                         withTimeout:timeout
                                                                                      timeoutHandler:handler];
    
    [PPOPaymentTrackingManager insertPaymentTrackingChapperone:chapperone];
    
    if (begin) {
        chapperone.state = PAYMENT_STATE_IN_PROGRESS;
        [chapperone startTimeoutTimer];
    }
    
}

+(void)overrideTimeoutHandler:(void(^)(void))handler forPayment:(PPOPayment*)payment {
    
    PPOPaymentTrackingChapperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    chapperone.timeoutHandler = handler;
    
}

+(void)removePayment:(PPOPayment*)payment {
    
    PPOPaymentTrackingChapperone *chapperoneToDiscard = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    
    [chapperoneToDiscard stopTimeoutTimer];
    
    [PPOPaymentTrackingManager removePaymentChapperone:chapperoneToDiscard];
    
}

+(PPOPaymentTrackingChapperone*)chapperoneForPayment:(PPOPayment*)payment {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    PPOPaymentTrackingChapperone *chapperone;
    
    for (PPOPaymentTrackingChapperone *c in manager.paymentChapperones) {
        
        if ([c.payment isEqual:payment]) {
            chapperone = c;
            break;
        }
        
    }
    
    return chapperone;
    
}

+(PAYMENT_STATE)stateForPayment:(PPOPayment*)payment {
    
    PPOPaymentTrackingChapperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    
    return (chapperone == nil || chapperone.payment == nil) ? PAYMENT_STATE_NON_EXISTENT : chapperone.state;
    
}

+(void)insertPaymentTrackingChapperone:(PPOPaymentTrackingChapperone*)chapperone {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    [manager.paymentChapperones addObject:chapperone];
    
}

+(void)removePaymentChapperone:(PPOPaymentTrackingChapperone*)chapperone {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    if ([manager.paymentChapperones containsObject:chapperone]) {
        [manager.paymentChapperones removeObject:chapperone];
    }
    
}

+(void)resumeTimeoutForPayment:(PPOPayment *)payment {
    
    PPOPaymentTrackingChapperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    chapperone.state = PAYMENT_STATE_IN_PROGRESS;
    
    [chapperone startTimeoutTimer];
    
}

+(void)suspendTimeoutForPayment:(PPOPayment *)payment {
    
    if (PPO_DEBUG_MODE) {
        NSLog(@"Suspending implementing developers timeout for payment with op ref: %@", payment.identifier);
    }
    
    PPOPaymentTrackingChapperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    chapperone.state = PAYMENT_STATE_SUSPENDED;
    
    [chapperone stopTimeoutTimer];
    
}

+(BOOL)masterSessionTimeoutHasExpiredForPayment:(PPOPayment *)payment {
    
    PPOPaymentTrackingChapperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    
    BOOL hasTimedOut = [chapperone masterSessionTimeoutHasExpired];
    
    if (hasTimedOut) {
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Inspecting master session timeout");
            NSLog(@"Implementing developers timeout is '0'");
        }
        
    }
    
    return hasTimedOut;
    
}

+(BOOL)allPaymentsComplete {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    PPOPaymentTrackingChapperone *chapperone;
    
    for (PPOPaymentTrackingChapperone *c in manager.paymentChapperones) {
        
        if (c.state != PAYMENT_STATE_NON_EXISTENT) {
            chapperone = c;
            break;
        }
    }
    
    return (chapperone == nil);
}

+(NSUInteger)totalRecursiveQueryPaymentAttemptsForPayment:(PPOPayment *)payment {
    PPOPaymentTrackingChapperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    return chapperone.queryPaymentCount;
}

+(void)incrementRecurisiveQueryPaymentAttemptCountForPayment:(PPOPayment *)payment {
    PPOPaymentTrackingChapperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    chapperone.queryPaymentCount++;
}

+(void (^)(void))timeoutHandlerForPayment:(PPOPayment *)payment {
    PPOPaymentTrackingChapperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    return chapperone.timeoutHandler;
}

+(NSTimeInterval)timeIntervalForAttemptCount:(NSUInteger)attempt {
    NSArray *timeIntervals = [PPOPaymentTrackingManager sharedManager].queryPaymentTimeIntervals;
    NSNumber *timeInterval;
    if (attempt <= (timeIntervals.count-1)) {
        timeInterval = timeIntervals[attempt];
    } else {
        timeInterval = timeIntervals.lastObject;
    }
    return timeInterval.doubleValue;
}

@end
