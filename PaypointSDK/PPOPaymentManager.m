//
//  PPOPaymentManager.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentManager.h"
#import "PPOBillingAddress.h"
#import "PPOPayment.h"
#import "PPOErrorManager.h"
#import "PPOPaymentsDispatchManager.h"
#import "PPOCreditCard.h"
#import "PPOLuhn.h"
#import "PPOCredentials.h"
#import "PPOTransaction.h"

@interface PPOPaymentManager ()
@property (nonatomic, strong, readwrite) NSURL *baseURL;
@property (nonatomic, strong) PPOPaymentsDispatchManager *paymentsDispatch;
@end

@implementation PPOPaymentManager

-(instancetype)initWithBaseURL:(NSURL*)baseURL {
    self = [super init];
    if (self) {
        _baseURL = baseURL;
    }
    return self;
}

-(PPOPaymentsDispatchManager *)paymentsDispatch {
    if (_paymentsDispatch == nil) {
        _paymentsDispatch = [PPOPaymentsDispatchManager new];
    }
    return _paymentsDispatch;
}

-(void)makePayment:(PPOPayment*)payment withCredentials:(PPOCredentials*)credentials withTimeOut:(CGFloat)timeout withCompletion:(void(^)(PPOOutcome *outcome, NSError *paymentFailure))completion {
    
    NSError *invalid = [PPOPaymentValidator validateCredentials:credentials validateBaseURL:self.baseURL validatePayment:payment];
    
    if (invalid) {
        completion(nil, invalid);
        return;
    }
    
    NSURL *url = [self simplePayment:credentials.installationID withBaseURL:self.baseURL];
    NSData *data = [self buildPostBodyWithTransaction:payment.transaction withCard:payment.card withAddress:payment.address];
    NSString *authorisation = [self authorisation:credentials];
    
    NSMutableURLRequest *request = [self mutableJSONPostRequest:url withTimeOut:timeout];
    [request setValue:authorisation forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:data];
    
    [self.paymentsDispatch dispatchRequest:[request copy] withTimeout:timeout withCredentials:credentials withCompletion:completion];
    
}

-(NSMutableURLRequest*)mutableJSONPostRequest:(NSURL*)url withTimeOut:(CGFloat)timeout {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeout];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    return request;
}

-(NSString*)authorisation:(PPOCredentials*)credentials {
    return [NSString stringWithFormat:@"Bearer %@", credentials.token];
}

-(NSData*)buildPostBodyWithTransaction:(PPOTransaction*)transaction
                              withCard:(PPOCreditCard*)card
                           withAddress:(PPOBillingAddress*)address {
    
    id value;
    id t;
    id c;
    id a;
    
    value = [transaction jsonObjectRepresentation];
    t = (value) ?: [NSNull null];
    value = [card jsonObjectRepresentation];
    c = (value) ?: [NSNull null];
    value = [address jsonObjectRepresentation];
    a = (value) ?: [NSNull null];
    
    id object = @{
                  @"transaction": t,
                  @"paymentMethod": @{
                                    @"card": c,
                                    @"billingAddress": a
                                    }
                  };
    
    return [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
}

@end

@implementation PPOPaymentValidator

+(NSError*)validateCredentials:(PPOCredentials*)credentials validateBaseURL:(NSURL*)baseURL validatePayment:(PPOPayment*)payment {
    
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
