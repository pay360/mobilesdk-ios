//
//  PPOPaymentValidator.m
//  Paypoint
//
//  Created by Robert Nash on 01/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOValidator.h"
#import "PPOPayment.h"
#import "PPOErrorManager.h"
#import "PPOTimeManager.h"
#import "PPOCredentials.h"
#import "PPOCreditCard.h"
#import "PPOLuhn.h"
#import "PPOTransaction.h"
#import "PPOPaymentTrackingManager.h"

@implementation PPOValidator

+(NSError*)validatePayment:(PPOPayment*)payment {
    
    return [self validateTransaction:payment.transaction
                            withCard:payment.card];
    
}

+(NSError*)validateBaseURL:(NSURL*)baseURL {
    if (!baseURL) {
        return [PPOErrorManager errorForCode:PPOErrorSuppliedBaseURLInvalid];
    }
    return nil;
}

+(NSError*)validateCredentials:(PPOCredentials*)credentials {
    
    if (!credentials) {
        return [PPOErrorManager errorForCode:PPOErrorCredentialsNotFound];
    }
    
    if (!credentials.token || credentials.token.length == 0) {
        return [PPOErrorManager errorForCode:PPOErrorClientTokenInvalid];
    }
    
    if (!credentials.installationID || credentials.installationID.length == 0) {
        return [PPOErrorManager errorForCode:PPOErrorInstallationIDInvalid];
    }
    
    return nil;
}

+(NSError*)validateTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card {
    
    NSString *strippedValue;
    
    strippedValue = [card.pan stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    BOOL containsLetters = [strippedValue rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location != NSNotFound;
    
    if (strippedValue.length < 13 || strippedValue.length > 19 || containsLetters) {
        return [PPOErrorManager errorForCode:PPOErrorCardPanInvalid];
    }
    
    if (![PPOLuhn validateString:strippedValue]) {
        return [PPOErrorManager errorForCode:PPOErrorLuhnCheckFailed];
    }
    
    strippedValue = [card.expiry stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length != 4) {
        return [PPOErrorManager errorForCode:PPOErrorCardExpiryDateInvalid];
    } else if ([PPOValidator cardExpiryHasExpired:strippedValue]) {
        return [PPOErrorManager errorForCode:PPOErrorCardExpiryDateExpired];
    }
    
    strippedValue = [card.cvv stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length < 3 || strippedValue.length > 4) {
        return [PPOErrorManager errorForCode:PPOErrorCVVInvalid];
    }
    
    strippedValue = [transaction.currency stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length == 0) {
        return [PPOErrorManager errorForCode:PPOErrorCurrencyInvalid];
    }
    
    if (transaction.amount == nil || transaction.amount.floatValue <= 0.0) {
        return [PPOErrorManager errorForCode:PPOErrorPaymentAmountInvalid];
    }
    
    return nil;
}

+(BOOL)cardExpiryHasExpired:(NSString*)expiry {
    return [PPOTimeManager cardExpiryDateExpired:expiry];
}

+(BOOL)baseURLInvalid:(NSURL*)url withHandler:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    NSError *invalid = [PPOValidator validateBaseURL:url];
    if (invalid) {
        outcomeHandler(nil, invalid);
        return YES;
    }
    return NO;
}

+(BOOL)credentialsInvalid:(PPOCredentials*)credentials withHandler:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    
    NSError *invalid = [PPOValidator validateCredentials:credentials];
    if (invalid) {
        outcomeHandler(nil, invalid);
        return YES;
    }
    return NO;
}

+(BOOL)paymentInvalid:(PPOPayment*)payment withHandler:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    
    NSError *invalid = [PPOValidator validatePayment:payment];
    if (invalid) {
        outcomeHandler(nil, invalid);
        return YES;
    }
    return NO;
}

+(BOOL)paymentUnderway:(PPOPayment*)payment withHandler:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    
    PAYMENT_STATE state = [PPOPaymentTrackingManager stateForPayment:payment];
    
    if (state != PAYMENT_STATE_NON_EXISTENT) {
        outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorPaymentProcessing]);
        return YES;
    }
    
    return NO;
}

@end
