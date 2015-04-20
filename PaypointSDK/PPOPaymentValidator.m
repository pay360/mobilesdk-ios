//
//  PPOPaymentValidator.m
//  Paypoint
//
//  Created by Robert Nash on 20/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentValidator.h"
#import "PPOErrorManager.h"
#import "PPOPayment.h"
#import "PPOLuhn.h"

@implementation PPOPaymentValidator

-(NSError*)validateCredentials:(PPOCredentials*)credentials validateBaseURL:(NSURL*)baseURL validatePayment:(PPOPayment*)payment {
    
    NSError *er;
    
    er = [self validateCredentials:credentials];
    
    if (er) {
        return er;
    }
    
    er = [self validatePayment:payment];
    
    if (er) {
        return er;
    }
    
    er = [self validateBaseURL:baseURL];
    
    if (er) {
        return er;
    }
    
    return nil;
}

-(NSError*)validatePayment:(PPOPayment*)payment {
    
    return [self validateTransaction:payment.transaction
                            withCard:payment.creditCard];
    
}

-(NSError*)validateBaseURL:(NSURL*)baseURL {
    if (!baseURL) {
        return [PPOErrorManager errorForCode:PPOErrorSuppliedBaseURLInvalid];
    }
    return nil;
}

-(NSError*)validateCredentials:(PPOCredentials*)credentials {
    
    if (!credentials) {
        return [PPOErrorManager errorForCode:PPOErrorCredentialsNotFound];
    }
    
    if (!credentials.installationID || credentials.installationID.length == 0) {
        return [PPOErrorManager errorForCode:PPOErrorInstallationIDInvalid];
    }
    
    return nil;
}

-(NSError*)validateTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card {
    
    NSString *strippedValue;
    
    strippedValue = [card.pan stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue.length < 13 || strippedValue.length > 19) {
        return [PPOErrorManager errorForCode:PPOErrorCardPanLengthInvalid];
    }
    
    if (![PPOLuhn validateString:strippedValue]) {
        return [PPOErrorManager errorForCode:PPOErrorLuhnCheckFailed];
    }
    
    strippedValue = [card.cvv stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length < 3 || strippedValue.length > 4) {
        return [PPOErrorManager errorForCode:PPOErrorCVVInvalid];
    }
    
    strippedValue = [card.expiry stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length != 4) {
        
        return [PPOErrorManager errorForCode:PPOErrorCardExpiryDateInvalid];
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

@end
