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
    
    NSError *invalid = [self validateCredentials:credentials validateBaseURL:self.baseURL validatePayment:payment];
    
    if (invalid) {
        completion(nil, invalid);
        return;
    }
    
    NSURL *url = [self simplePayment:credentials.installationID withBaseURL:self.baseURL];
    NSData *data = [self buildPostBodyWithTransaction:payment.transaction withCard:payment.creditCard withAddress:payment.billingAddress];
    NSString *authorisation = [self authorisation:credentials];
    
    NSMutableURLRequest *request = [self mutableJSONPostRequest:url withTimeOut:timeout];
    [request setValue:authorisation forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:data];
    
    [self.paymentsDispatch dispatchRequest:[request copy] withCompletion:completion];
    
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
