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
#import "PPOErrorManager.h"

@interface PPOOutcome ()
@property (nonatomic, strong, readwrite) NSNumber *amount;
@property (nonatomic, strong, readwrite) NSString *currency;
@property (nonatomic, strong, readwrite) NSDate *date;
@property (nonatomic, strong, readwrite) NSString *merchantRef;
@property (nonatomic, strong, readwrite) NSString *type;
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSString *lastFour;
@property (nonatomic, strong, readwrite) NSString *cardUsageType;
@property (nonatomic, strong, readwrite) NSString *cardScheme;
@property (nonatomic, strong, readwrite) NSSet *customFields;
@property (nonatomic, strong) PPOTimeManager *timeManager;
@end

@implementation PPOOutcome

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
            
            [self parseTransaction:[data objectForKey:TRANSACTION_RESPONSE_TRANSACTION_KEY]];
            
            id paymentMethod = [data objectForKey:TRANSACTION_RESPONSE_METHOD_KEY];
            
            if ([paymentMethod isKindOfClass:[NSDictionary class]]) [self parseCard:[paymentMethod objectForKey:TRANSACTION_RESPONSE_METHOD_CARD_KEY]];
            
        }
        
    }
    
    return self;
}

-(instancetype)initWithError:(NSError *)error {
    self = [super init];
    if (self) {
        _error = error;
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
            if (((NSNumber*)value).integerValue > 0) {
                self.error = [PPOErrorManager errorForCode:[PPOErrorManager errorCodeForReasonCode:((NSNumber*)value).integerValue]];
            }
        }
    }
}

-(void)parseTransaction:(NSDictionary*)transaction {
    id value;
    if ([transaction isKindOfClass:[NSDictionary class]]) {
        value = [transaction objectForKey:TRANSACTION_RESPONSE_TRANSACTION_AMOUNT_KEY];
        if ([value isKindOfClass:[NSNumber class]]) {
            self.amount = value;
        }
        value = [transaction objectForKey:TRANSACTION_RESPONSE_TRANSACTION_CURRENCY_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.currency = value;
        }
        value = [transaction objectForKey:TRANSACTION_RESPONSE_TRANSACTION_TIME_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.date = [self.timeManager dateFromString:value];
        }
        value = [transaction objectForKey:TRANSACTION_RESPONSE_TRANSACTION_MERCH_REF_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.merchantRef = value;
        }
        value = [transaction objectForKey:TRANSACTION_RESPONSE_TRANSACTION_TYPE_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.type = value;
        }
        value = [transaction objectForKey:TRANSACTION_RESPONSE_TRANSACTION_ID_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.identifier = value;
        }
    }
}

-(void)parseCard:(NSDictionary*)card {
    id value;
    if ([card isKindOfClass:[NSDictionary class]]) {
        value = [card objectForKey:TRANSACTION_RESPONSE_METHOD_CARD_LAST_FOUR_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.lastFour = value;
        }
        value = [card objectForKey:TRANSACTION_RESPONSE_METHOD_CARD_USER_TYPE_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.cardUsageType = value;
        }
        value = [card objectForKey:TRANSACTION_RESPONSE_METHOD_CARD_SCHEME_KEY];
        if ([value isKindOfClass:[NSString class]]) {
            self.cardScheme = value;
        }
    }
}

@end
