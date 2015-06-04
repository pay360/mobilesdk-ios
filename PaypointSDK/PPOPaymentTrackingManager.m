//
//  PPOPaymentTrackingManager.m
//  Paypoint
//
//  Created by Robert Nash on 29/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentTrackingManager.h"
#import "PPOPayment.h"

@interface PPOPaymentTrackingChapperone : NSObject
//The payment is weak here. If no other object is using it, we will discard it.
//The payment tracker will report back with 'non-existent'
@property (nonatomic, weak) PPOPayment *payment;
@property (nonatomic, readonly) NSTimeInterval sessionTimeout;
@property (nonatomic) PAYMENT_STATE state;
-(instancetype)initWithPayment:(PPOPayment*)payment withTimeout:(NSTimeInterval)timeout;
-(void)startTimeoutTimer;
-(void)stopTimeoutTimer;
-(BOOL)hasTimedout;
@end

@interface PPOPaymentTrackingChapperone ()
@property (nonatomic, readwrite) NSTimeInterval sessionTimeout;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) void(^timeoutHandler)(void);
@end

@implementation PPOPaymentTrackingChapperone

-(instancetype)initWithPayment:(PPOPayment *)payment withTimeout:(NSTimeInterval)timeout {
    self = [super init];
    if (self) {
        _payment = payment;
        _state = PAYMENT_STATE_READY;
        if (timeout < 0.0f) {
            timeout = 0;
        }
        _sessionTimeout = timeout;
    }
    return self;
}

-(BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    return [self isEqualToPaymentTrackingChapperone:object];
}

-(BOOL)isEqualToPaymentTrackingChapperone:(PPOPaymentTrackingChapperone*)chapperone {
    return (chapperone && [chapperone isKindOfClass:[PPOPaymentTrackingChapperone class]] && [self.payment isEqual:chapperone.payment]);
}

-(void)startTimeoutTimer {
    if (self.sessionTimeout >= 0) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timeoutTimerFired:) userInfo:nil repeats:YES];
    }
}

-(void)stopTimeoutTimer {
    [self.timer invalidate];
    self.timer = nil;
}

-(void)timeoutTimerFired:(NSTimer*)timer {
    if (self.sessionTimeout <= 0) {
        [timer invalidate];
        timer = nil;
        self.timeoutHandler();
    } else {
        self.sessionTimeout--;
    }
}

-(BOOL)hasTimedout {
    return (self.sessionTimeout <= 0);
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

+(void)appendPayment:(PPOPayment*)payment withTimeout:(NSTimeInterval)timeout commenceTimeoutImmediately:(BOOL)begin timeoutHandler:(void(^)(void))handler {
    
    PPOPaymentTrackingChapperone *chapperone = [[PPOPaymentTrackingChapperone alloc] initWithPayment:payment withTimeout:timeout];
    chapperone.timeoutHandler = handler;
    
    [PPOPaymentTrackingManager insertPaymentTrackingChapperone:chapperone];
    
    if (begin) {
        chapperone.state = PAYMENT_STATE_IN_PROGRESS;
        [chapperone startTimeoutTimer];
    }
    
}

+(void)setTimeoutHandler:(void(^)(void))handler forPayment:(PPOPayment*)payment {
    
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

+(NSNumber*)hasPaymentSessionTimedoutForPayment:(PPOPayment *)payment {
    
    PPOPaymentTrackingChapperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    
    return (chapperone != nil) ? @([chapperone hasTimedout]) : nil;
    
}

+(NSNumber *)remainingSessionTimeoutForPayment:(PPOPayment *)payment {
    
    PPOPaymentTrackingChapperone *chapperone = [PPOPaymentTrackingManager chapperoneForPayment:payment];
    
    return (chapperone != nil) ? @(chapperone.sessionTimeout) : nil;
    
}

@end
