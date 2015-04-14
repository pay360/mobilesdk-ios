//
//  PPOOutcome.m
//  Paypoint
//
//  Created by Robert Nash on 10/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOOutcome.h"
#import "PPOErrorManager.h"
#import "PPOTimeManager.h"

@interface PPOOutcome ()
@property (nonatomic, strong, readwrite) NSNumber *amount;
@property (nonatomic, strong, readwrite) NSString *currency;
@property (nonatomic, strong, readwrite) NSDate *date;
@property (nonatomic, strong, readwrite) NSString *merchantRef;
@property (nonatomic, strong, readwrite) NSString *type;
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong) NSString *localisedReason;
@property (nonatomic, strong, readwrite) NSNumber *reasonCode;
@property (nonatomic, strong, readwrite) NSString *lastFour;
@property (nonatomic, strong, readwrite) NSString *cardUsageType;
@property (nonatomic, strong, readwrite) NSString *cardScheme;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong) PPOTimeManager *timeManager;
@end

@implementation PPOOutcome

-(NSNumber *)reasonCode {
    if (_reasonCode == nil) {
        _reasonCode = @(PPOErrorNotInitialised);
    }
    return _reasonCode;
}

-(PPOTimeManager *)timeManager {
    if (_timeManager == nil) {
        _timeManager = [PPOTimeManager new];
    }
    return _timeManager;
}

-(instancetype)initWithData:(NSDictionary*)data withError:(NSError*)error {
    self = [super init];
    
    if (self) {
        
        _error = error;
        
        id value;
        
        value = [data objectForKey:@"outcome"];
        
        [self parseOutcome:value];
        
        value = [data objectForKey:@"transaction"];
        
        [self parseTransaction:value];
        
        value = [data objectForKey:@"paymentMethod"];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            
            value = [value objectForKey:@"card"];
            
            [self parseCard:value];
        }
        
        if (_localisedReason && _reasonCode.integerValue > 0) {
            
            NSDictionary *userInfo;
            NSString *errorDomain;
            PPOErrorCode code;
            
            userInfo = @{NSLocalizedFailureReasonErrorKey: _localisedReason};
            
            errorDomain = [PPOErrorManager errorDomainForReasonCode:_reasonCode.integerValue];
            
            code = [PPOErrorManager errorCodeForReasonCode:_reasonCode.integerValue];
            
            // This error supercedes any error passed into this method
            _error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
        }
        
    }
    
    return self;
}

-(void)parseOutcome:(NSDictionary*)outcome {
    id value;
    if ([outcome isKindOfClass:[NSDictionary class]]) {
        value = [outcome objectForKey:@"reasonCode"];
        if ([value isKindOfClass:[NSNumber class]]) {
            self.reasonCode = value;
        }
        value = [outcome objectForKey:@"reasonMessage"];
        if ([value isKindOfClass:[NSString class]]) {
            self.localisedReason = value;
        }
    }
}

-(void)parseTransaction:(NSDictionary*)transaction {
    id value;
    if ([transaction isKindOfClass:[NSDictionary class]]) {
        value = [transaction objectForKey:@"amount"];
        if ([value isKindOfClass:[NSString class]]) {
            self.amount = value;
        }
        value = [transaction objectForKey:@"currency"];
        if ([value isKindOfClass:[NSString class]]) {
            self.currency = value;
        }
        value = [transaction objectForKey:@"transactionTime"];
        if ([value isKindOfClass:[NSString class]]) {
            self.date = [self.timeManager dateFromString:value];
        }
        value = [transaction objectForKey:@"merchantRef"];
        if ([value isKindOfClass:[NSString class]]) {
            self.merchantRef = value;
        }
        value = [transaction objectForKey:@"type"];
        if ([value isKindOfClass:[NSString class]]) {
            self.type = value;
        }
        value = [transaction objectForKey:@"transactionId"];
        if ([value isKindOfClass:[NSString class]]) {
            self.identifier = value;
        }
    }
}

-(void)parseCard:(NSDictionary*)card {
    id value;
    if ([card isKindOfClass:[NSDictionary class]]) {
        value = [card objectForKey:@"lastFour"];
        if ([value isKindOfClass:[NSString class]]) {
            self.lastFour = value;
        }
        value = [card objectForKey:@"cardUsageType"];
        if ([value isKindOfClass:[NSString class]]) {
            self.cardUsageType = value;
        }
        value = [card objectForKey:@"cardScheme"];
        if ([value isKindOfClass:[NSString class]]) {
            self.cardScheme = value;
        }
    }
}

@end
