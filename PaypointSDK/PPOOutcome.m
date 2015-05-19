//
//  PPOOutcome.m
//  Paypoint
//
//  Created by Robert Nash on 10/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOOutcome.h"
#import "PPOError.h"
#import "PPOTimeManager.h"
#import "PPOSDKConstants.h"
#import "PPOCustomField.h"

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
@property (nonatomic, strong, readwrite) NSSet *customFields;
@property (nonatomic, readwrite) BOOL isSuccessful;
@property (nonatomic, strong) PPOTimeManager *timeManager;
@end

@implementation PPOOutcome

-(NSNumber *)reasonCode {
    if (_reasonCode == nil) {
        _reasonCode = @(PPOErrorNotInitialised);
    }
    return _reasonCode;
}

-(BOOL)isSuccessful {
    return (self.reasonCode) ? self.reasonCode.integerValue == 0 : NO;
}

-(PPOTimeManager *)timeManager {
    if (_timeManager == nil) {
        _timeManager = [PPOTimeManager new];
    }
    return _timeManager;
}

-(instancetype)initWithData:(NSDictionary*)data {
    
    if (!data) return nil;
    
    self = [super init];
    
    if (self) {
        
        if (data) {
            
            [self parseCustomFields:[data objectForKey:PAYMENT_RESPONSE_CUSTOM_FIELDS]];
            
            [self parseOutcome:[data objectForKey:PAYMENT_RESPONSE_OUTCOME_KEY]];
            
            [self parseTransaction:[data objectForKey:PAYMENT_RESPONSE_TRANSACTION_KEY]];
            
            id paymentMethod = [data objectForKey:PAYMENT_RESPONSE_METHOD_KEY];
            
            if ([paymentMethod isKindOfClass:[NSDictionary class]]) [self parseCard:[paymentMethod objectForKey:PAYMENT_RESPONSE_METHOD_CARD_KEY]];
            
        }
        
    }
    
    return self;
}

-(void)parseCustomFields:(NSDictionary*)customFields {
    
    NSArray *fieldState = [customFields objectForKey:PAYMENT_RESPONSE_CUSTOM_FIELDS_STATE];
    if ([fieldState isKindOfClass:[NSArray class]]) {
        NSMutableSet *collector = [NSMutableSet new];
        PPOCustomField *field;
        for (id object in fieldState) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                field = [[PPOCustomField alloc] initWithData:object];
                [collector addObject:field];
            }
        }
        self.customFields = [collector copy];
    }
    
}

-(void)parseOutcome:(NSDictionary*)outcome {
    id value;
    if ([outcome isKindOfClass:[NSDictionary class]]) {
        value = [outcome objectForKey:PAYMENT_RESPONSE_OUTCOME_REASON_KEY];
        if ([value isKindOfClass:[NSNumber class]]) {
            self.reasonCode = value;
        }
        value = [outcome objectForKey:PAYMENT_RESPONSE_OUTCOME_REASON_MESSAGE_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.localisedReason = value;
        }
    }
}

-(void)parseTransaction:(NSDictionary*)transaction {
    id value;
    if ([transaction isKindOfClass:[NSDictionary class]]) {
        value = [transaction objectForKey:PAYMENT_RESPONSE_TRANSACTION_AMOUNT_KEY];
        if ([value isKindOfClass:[NSNumber class]]) {
            self.amount = value;
        }
        value = [transaction objectForKey:PAYMENT_RESPONSE_TRANSACTION_CURRENCY_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.currency = value;
        }
        value = [transaction objectForKey:PAYMENT_RESPONSE_TRANSACTION_TIME_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.date = [self.timeManager dateFromString:value];
        }
        value = [transaction objectForKey:PAYMENT_RESPONSE_TRANSACTION_MERCH_REF_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.merchantRef = value;
        }
        value = [transaction objectForKey:PAYMENT_RESPONSE_TRANSACTION_TYPE_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.type = value;
        }
        value = [transaction objectForKey:PAYMENT_RESPONSE_TRANSACTION_ID_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.identifier = value;
        }
    }
}

-(void)parseCard:(NSDictionary*)card {
    id value;
    if ([card isKindOfClass:[NSDictionary class]]) {
        value = [card objectForKey:PAYMENT_RESPONSE_METHOD_CARD_LAST_FOUR_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.lastFour = value;
        }
        value = [card objectForKey:PAYMENT_RESPONSE_METHOD_CARD_USER_TYPE_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.cardUsageType = value;
        }
        value = [card objectForKey:PAYMENT_RESPONSE_METHOD_CARD_SCHEME_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.cardScheme = value;
        }
    }
}

@end
