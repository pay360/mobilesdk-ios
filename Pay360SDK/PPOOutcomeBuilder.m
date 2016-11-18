//
//  PPOOutcomeBuilder.m
//  Pay360
//
//  Created by Robert Nash on 12/06/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import "PPOOutcomeBuilder.h"
#import "PPOTimeManager.h"
#import "PPOSDKConstants.h"
#import "PPOCustomField.h"
#import "PPOErrorManager.h"
#import "PPOCustomFieldBuilder.h"

@interface PPOOutcomeBuilder ()
@end

@implementation PPOOutcomeBuilder

+(PPOOutcome*)outcomeWithData:(NSDictionary*)data withError:(NSError*)error forPayment:(PPOPayment *)payment {
    
    PPOOutcome *outcome = [PPOOutcome new];
    outcome.payment = payment;
    outcome.error = error;
    
    if (data) {
        [PPOOutcomeBuilder parseCustomFields:[data objectForKey:PAYMENT_RESPONSE_CUSTOM_FIELDS]
                                  forOutcome:outcome];
        
        [PPOOutcomeBuilder parseOutcome:[data objectForKey:PAYMENT_RESPONSE_OUTCOME_KEY]
                             forOutcome:outcome];
        
        [PPOOutcomeBuilder parseTransaction:[data objectForKey:TRANSACTION_RESPONSE_TRANSACTION_KEY]
                                 forOutcome:outcome];
        
        id paymentMethod = [data objectForKey:TRANSACTION_RESPONSE_METHOD_KEY];
        
        if ([paymentMethod isKindOfClass:[NSDictionary class]]) {
            [PPOOutcomeBuilder parseCard:[paymentMethod objectForKey:TRANSACTION_RESPONSE_METHOD_CARD_KEY]
                              forOutcome:outcome];
        }
    }
    
    return outcome;
}

+(void)parseCustomFields:(NSDictionary*)customFields forOutcome:(PPOOutcome*)outcome {
    
    if (!customFields || ![customFields isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSArray *fieldState = [customFields objectForKey:PAYMENT_RESPONSE_CUSTOM_FIELDS_STATE];
    if ([fieldState isKindOfClass:[NSArray class]]) {
        NSMutableSet *collector = [NSMutableSet new];
        PPOCustomField *field;
        for (id object in fieldState) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                field = [PPOCustomFieldBuilder customFieldWithData:object];
                [collector addObject:field];
            }
        }
        outcome.customFields = [collector copy];
    }
    
}

+(void)parseOutcome:(NSDictionary*)outcomeData forOutcome:(PPOOutcome*)outcome {
    
    if (!outcomeData || ![outcomeData isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    id value1;
    if ([outcomeData isKindOfClass:[NSDictionary class]]) {
        value1 = [outcomeData objectForKey:PAYMENT_RESPONSE_OUTCOME_REASON_CODE_KEY];
        
        //Number on stub, string on mite. This will be raised as a change soon.
        if ([value1 isKindOfClass:[NSNumber class]] || [value1 isKindOfClass:[NSString class]]) {
            if (((NSNumber*)value1).integerValue > 0) {
                id value2 = [outcomeData objectForKey:PAYMENT_RESPONSE_OUTCOME_REASON_KEY];
                outcome.error = [PPOErrorManager parsePay360ReasonCode:((NSNumber*)value1).integerValue withMessage:([value2 isKindOfClass:[NSString class]]) ? value2 : nil];
            }
        }

    }
}

+(void)parseTransaction:(NSDictionary*)transaction forOutcome:(PPOOutcome*)outcome {
    id value;
    
    if (!transaction || ![transaction isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    PPOTimeManager *manager = [PPOTimeManager new];
    
    value = [transaction objectForKey:TRANSACTION_RESPONSE_TRANSACTION_AMOUNT_KEY];
    if ([value isKindOfClass:[NSNumber class]]) {
        outcome.amount = value;
    }
    value = [transaction objectForKey:TRANSACTION_RESPONSE_TRANSACTION_CURRENCY_KEY];
    if ([value isKindOfClass:[NSString class]]) {
        outcome.currency = value;
    }
    value = [transaction objectForKey:TRANSACTION_RESPONSE_TRANSACTION_TIME_KEY];
    if ([value isKindOfClass:[NSString class]]) {
        outcome.date = [manager dateFromString:value];
    }
    value = [transaction objectForKey:TRANSACTION_RESPONSE_TRANSACTION_MERCH_REF_KEY];
    if ([value isKindOfClass:[NSString class]]) {
        outcome.merchantRef = value;
    }
    value = [transaction objectForKey:TRANSACTION_RESPONSE_TRANSACTION_TYPE_KEY];
    if ([value isKindOfClass:[NSString class]]) {
        outcome.type = value;
    }
    value = [transaction objectForKey:TRANSACTION_RESPONSE_TRANSACTION_ID_KEY];
    if ([value isKindOfClass:[NSString class]]) {
        outcome.identifier = value;
    }
    
}

+(void)parseCard:(NSDictionary*)card forOutcome:(PPOOutcome*)outcome {
    
    if (!card || ![card isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    id value;
    
    value = [card objectForKey:TRANSACTION_RESPONSE_METHOD_CARD_LAST_FOUR_KEY];
    if ([value isKindOfClass:[NSString class]]) {
        outcome.lastFour = value;
    }
    value = [card objectForKey:TRANSACTION_RESPONSE_METHOD_CARD_USER_TYPE_KEY];
    if ([value isKindOfClass:[NSString class]]) {
        outcome.cardUsageType = value;
    }
    value = [card objectForKey:TRANSACTION_RESPONSE_METHOD_CARD_SCHEME_KEY];
    if ([value isKindOfClass:[NSString class]]) {
        outcome.cardScheme = value;
    }
    value = [card objectForKey:TRANSACTION_RESPONSE_METHOD_CARD_MASKED_PAN_KEY];
    if ([value isKindOfClass:[NSString class]]) {
        outcome.maskedPan = value;
    }
}

@end
