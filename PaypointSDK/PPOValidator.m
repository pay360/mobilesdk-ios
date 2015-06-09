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

+(NSError*)validateTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card {
    
    NSString *strippedValue;
    
    strippedValue = [card.pan stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    BOOL containsLetters = [strippedValue rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location != NSNotFound;
    
    if (strippedValue.length < 13 || strippedValue.length > 19 || containsLetters) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCardPanInvalid];
    } else if (![PPOLuhn validateString:strippedValue]) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCardPanInvalid];
    }
    
    strippedValue = [card.expiry stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length != 4) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCardExpiryDateInvalid];
    } else if ([PPOValidator cardExpiryHasExpired:strippedValue]) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCardExpiryDateExpired];
    }
    
    strippedValue = [card.cvv stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length < 3 || strippedValue.length > 4) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCVVInvalid];
    }
    
    strippedValue = [transaction.currency stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length == 0) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorCurrencyInvalid];
    }
    
    if (transaction.amount == nil || transaction.amount.floatValue <= 0.0) {
        return [PPOErrorManager buildErrorForValidationErrorCode:PPOLocalValidationErrorPaymentAmountInvalid];
    }
    
    return nil;
}

+(BOOL)cardExpiryHasExpired:(NSString*)expiry {
    return [PPOTimeManager cardExpiryDateExpired:expiry];
}

@end
