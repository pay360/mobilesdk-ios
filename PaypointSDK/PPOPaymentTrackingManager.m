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
@property (nonatomic) PAYMENT_STATE state;
-(instancetype)initWithPayment:(PPOPayment *)payment withTimeout:(NSTimeInterval)timeout timeoutHandler:(void(^)(void))timeoutHandler;
-(void)startTimeoutTimer;
-(void)stopTimeoutTimer;
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
            NSLog(@"Starting implementing developers timeout for payment with op ref: %@", self.payment.identifier);
        }
    }
    
}

-(void)stopTimeoutTimer {
    if (PPO_DEBUG_MODE) {
        NSLog(@"Stopping implementing developers timeout for payment with op ref: %@ with remaining time %f", self.payment.identifier, self.sessionTimeout);
    }
    [self.timer invalidate];
    self.timer = nil;
}

-(void)timeoutTimerFired:(NSTimer*)timer {
    
    if (timer.isValid) {
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Session terminates in t-minus %f seconds for payment with op ref %@", self.sessionTimeout, self.payment.identifier);
        }
        
        if (self.sessionTimeout <= 0) {
            [timer invalidate];
            timer = nil;
            [PPOPaymentTrackingManager removePayment:self.payment];
            self.timeoutHandler();
        } else {
            self.sessionTimeout--;
        }
    }
    
}

@end

@interface PPOPaymentTrackingManager ()
@property (nonatomic, strong) NSMutableSet *paymentChapperones;
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
    
    PPOPaymentTrackingChapperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    chapperone.state = PAYMENT_STATE_SUSPENDED;
    
    [chapperone stopTimeoutTimer];
    
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

@end
