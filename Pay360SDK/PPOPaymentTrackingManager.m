//
//  PPOPaymentTrackingManager.m
//  Pay360
//
//  Created by Robert Nash on 29/05/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import "PPOPaymentTrackingManager.h"
#import "PPOPayment.h"
#import "PPOSDKConstants.h"

@interface PPOPaymentTrackingChaperone : NSObject
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

@interface PPOPaymentTrackingChaperone ()
@property (nonatomic, readwrite) NSTimeInterval sessionTimeout;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) void(^timeoutHandler)(void);
@end

@implementation PPOPaymentTrackingChaperone

-(instancetype)initWithPayment:(PPOPayment *)payment withTimeout:(NSTimeInterval)timeout timeoutHandler:(void(^)(void))timeoutHandler {
    self = [super init];
    if (self) {
        _payment = payment;
        _state = PAYMENT_STATE_READY;
        if (timeout < 0.0f) {
            timeout = 0;
        } else if (timeout >= 1) {
            timeout = (timeout -1);
        }
        _sessionTimeout = timeout;
        _timeoutHandler = timeoutHandler;
    }
    return self;
}

-(BOOL)isEqual:(id)object {
    PPOPaymentTrackingChaperone *chapperone;
    if ([object isKindOfClass:[PPOPaymentTrackingChaperone class]]) {
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
    }
    
}

-(void)stopTimeoutTimer {
    [self.timer invalidate];
    self.timer = nil;
}

-(void)timeoutTimerFired:(NSTimer*)timer {
    
    if (timer.isValid) {
        
#if PPO_DEBUG_MODE
        PPOPaymentReference *reference = objc_getAssociatedObject(self.payment, &kPaymentIdentifierKey);
        NSString *message = (self.sessionTimeout == 1) ? @"second" : @"seconds";
        NSLog(@"Master session timeout is %f %@ for payment with op ref %@", self.sessionTimeout, message, reference.identifier);
#endif
        
        if (self.sessionTimeout <= 0) {
        
#if PPO_DEBUG_MODE
    NSLog(@"Master session timeout has expired");
#endif
            
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
    
    PPOPaymentTrackingChaperone *chapperone = [[PPOPaymentTrackingChaperone alloc] initWithPayment:payment
                                                                                         withTimeout:timeout
                                                                                      timeoutHandler:handler];
    
    [PPOPaymentTrackingManager insertPaymentTrackingChapperone:chapperone];
    
    if (begin) {
        chapperone.state = PAYMENT_STATE_IN_PROGRESS;
        [chapperone startTimeoutTimer];
    }
    
}

+(void)overrideTimeoutHandler:(void(^)(void))handler forPayment:(PPOPayment*)payment {
    
    PPOPaymentTrackingChaperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    chapperone.timeoutHandler = handler;
    
}

+(void)removePayment:(PPOPayment*)payment {
    
    PPOPaymentTrackingChaperone *chapperoneToDiscard = [PPOPaymentTrackingManager chapperoneForPayment:payment];

    [chapperoneToDiscard stopTimeoutTimer];
    
    [PPOPaymentTrackingManager removePaymentChapperone:chapperoneToDiscard];
    
}

+(PPOPaymentTrackingChaperone*)chapperoneForPayment:(PPOPayment*)payment {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    PPOPaymentTrackingChaperone *chapperone;
    
    for (PPOPaymentTrackingChaperone *c in manager.paymentChapperones) {
        
        if ([c.payment isEqual:payment]) {
            chapperone = c;
            break;
        }
        
    }
    
    return chapperone;
    
}

+(PAYMENT_STATE)stateForPayment:(PPOPayment*)payment {
    
    PPOPaymentTrackingChaperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    
    return (chapperone == nil || chapperone.payment == nil) ? PAYMENT_STATE_NON_EXISTENT : chapperone.state;
    
}

+(void)insertPaymentTrackingChapperone:(PPOPaymentTrackingChaperone*)chapperone {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    [manager.paymentChapperones addObject:chapperone];
    
}

+(void)removePaymentChapperone:(PPOPaymentTrackingChaperone*)chapperone {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    if ([manager.paymentChapperones containsObject:chapperone]) {
        [manager.paymentChapperones removeObject:chapperone];
    }
    
}

+(void)resumeTimeoutForPayment:(PPOPayment *)payment {
    
    PPOPaymentTrackingChaperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    chapperone.state = PAYMENT_STATE_IN_PROGRESS;
    
    [chapperone startTimeoutTimer];
    
}

+(void)suspendTimeoutForPayment:(PPOPayment *)payment {
    
#if PPO_DEBUG_MODE
    PPOPaymentReference *reference = objc_getAssociatedObject(payment, &kPaymentIdentifierKey);
    NSLog(@"Suspending master session timeout for payment with op ref: %@", reference.identifier);
#endif
    
    PPOPaymentTrackingChaperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    chapperone.state = PAYMENT_STATE_SUSPENDED;
    
    [chapperone stopTimeoutTimer];
    
}

+(BOOL)paymentIsBeingTracked:(PPOPayment*)payment {
    
    PPOPaymentTrackingChaperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    
    return (chapperone != nil);
}

+(BOOL)masterSessionTimeoutHasExpiredForPayment:(PPOPayment *)payment {
    
    PPOPaymentTrackingChaperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    
    BOOL hasTimedOut = [chapperone masterSessionTimeoutHasExpired];
    
    if (hasTimedOut) {
        
#if PPO_DEBUG_MODE
    NSLog(@"Master session has fully counted down to zero");
#endif
        
    }
    
    return hasTimedOut;
    
}

+(BOOL)allPaymentsComplete {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    PPOPaymentTrackingChaperone *chapperone;
    
    for (PPOPaymentTrackingChaperone *c in manager.paymentChapperones) {
        
        if (c.state != PAYMENT_STATE_NON_EXISTENT) {
            chapperone = c;
            break;
        }
    }
    
    return (chapperone == nil);
}

+(NSUInteger)totalQueryPaymentAttemptsForPayment:(PPOPayment *)payment {
    PPOPaymentTrackingChaperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    return chapperone.queryPaymentCount;
}

+(void)incrementQueryPaymentAttemptCountForPayment:(PPOPayment *)payment {
    PPOPaymentTrackingChaperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    chapperone.queryPaymentCount++;
}

+(void (^)(void))timeoutHandlerForPayment:(PPOPayment *)payment {
    PPOPaymentTrackingChaperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
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
