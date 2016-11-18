//
//  PPOPaymentValidator.m
//  Pay360
//
//  Created by Robert Nash on 01/06/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import "PPOValidator.h"
#import "PPOPayment.h"
#import "PPOErrorManager.h"
#import "PPOTimeManager.h"
#import "PPOCredentials.h"
#import "PPOCard.h"
#import "PPOLuhn.h"
#import "PPOTransaction.h"
#import "PPOPaymentTrackingManager.h"

@implementation PPOValidator

#pragma mark - Network

+(NSError*)validateBaseURL:(NSURL*)baseURL {
    if (!baseURL) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorSuppliedBaseURLInvalid];
    }
    return nil;
}

+(NSError*)validateCredentials:(PPOCredentials*)credentials {
    
    if (!credentials) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCredentialsNotFound];
    }
    
    if (!credentials.token || credentials.token.length == 0) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorClientTokenInvalid];
    }
    
    if (!credentials.installationID || credentials.installationID.length == 0) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorInstallationIDInvalid];
    }
    
    return nil;
}

#pragma mark - Payment 

+(NSError*)validatePayment:(PPOPayment*)payment {
    
    NSError *error;
    
    error = [PPOValidator validateCard:payment.card];
    if (error) return error;
    
    error = [PPOValidator validateTransaction:payment.transaction];
    if (error) return error;
    
    return nil;
}

#pragma mark - ValidateCard

+(NSError *)validateCard:(PPOCard *)card {
    
    NSError *error;
    
    error = [PPOValidator validateCardPan:card.pan];;
    if (error) return error;
    
    error = [PPOValidator validateCardExpiry:card.expiry];
    if (error) return error;
    
    error = [PPOValidator validateCardCVV:card.cvv];
    if (error) return error;
    
    return error;
}

+(NSError*)validateCardPan:(NSString*)pan {
    
    NSString *strippedValue;
    
    strippedValue = [pan stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    BOOL containsLetters = [strippedValue rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location != NSNotFound;
    
    if (strippedValue.length < 13 || strippedValue.length > 19 || containsLetters) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCardPanInvalid];
    } else if (![PPOLuhn validateString:strippedValue]) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCardPanInvalid];
    }
    
    return nil;
}

+(NSError*)validateCardExpiry:(NSString*)expiry {
    
    NSString *strippedValue;
    
    strippedValue = [expiry stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length != 4) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCardExpiryDateInvalid];
    } else if ([PPOValidator cardExpiryHasExpired:strippedValue]) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCardExpiryDateExpired];
    }
    
    return nil;
}

+(BOOL)cardExpiryHasExpired:(NSString*)expiry {
    return [PPOTimeManager cardExpiryDateExpired:expiry];
}

+(NSError*)validateCardCVV:(NSString*)cvv {
    
    NSString *strippedValue;
    
    strippedValue = [cvv stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length < 3 || strippedValue.length > 4) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCVVInvalid];
    }
    
    return nil;
}

#pragma mark - Validate Transaction

+(NSError*)validateTransaction:(PPOTransaction*)transaction {
    
    NSError *error;
    
    error = [PPOValidator validateCurrency:transaction.currency];
    if (error) return error;
    
    error = [PPOValidator validateAmount:transaction.amount];
    if (error) return error;
    
    return error;
}

+(NSError*)validateCurrency:(NSString*)currency {
    
    NSString *strippedValue;
    
    strippedValue = [currency stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length == 0) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCurrencyInvalid];
    }
    
    return nil;
}

+(NSError*)validateAmount:(NSNumber*)amount {
    
    if (amount == nil || amount.floatValue <= 0.0) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorPaymentAmountInvalid];
    }
    
    return nil;
}

@end
