//
//  PPOPaymentManager.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentManager.h"
#import "PPOCreditCard.h"
#import "PPOCredentials.h"
#import "PPOTransaction.h"
#import "PPOBillingAddress.h"
#import "PPOOutcomeManager.h"
#import "PPOLuhn.h"
#import "PPOPayment.h"
#import "PPOBaseURLManager.h"
#import "PPOErrorManager.h"

@interface PPOPaymentManager () <NSURLSessionTaskDelegate>
@property (nonatomic, strong, readwrite) NSURL *baseURL;
@end

@interface PPOEndpointManager : NSObject
+(NSURL*)simplePayment:(NSString*)installationID withBaseURL:(NSURL*)baseURL;
@end

@implementation PPOPaymentManager

-(instancetype)initWithBaseURL:(NSURL*)baseURL {
    self = [super init];
    if (self) {
        _baseURL = baseURL;
    }
    return self;
}

-(void)makePayment:(PPOPayment*)payment withCredentials:(PPOCredentials*)credentials withTimeOut:(CGFloat)timeout withCompletion:(void(^)(PPOOutcome *outcome))completion {
    
    __block PPOOutcome *outcome;
    
    outcome = [self validateCredentials:credentials];
    
    if (outcome) {
        completion(outcome);
        return;
    }
    
    outcome = [self validatePayment:payment];
    
    if (outcome) {
        completion(outcome);
        return;
    }
    
    outcome = [self validateBaseURL:self.baseURL];
    
    if (outcome) {
        completion(outcome);
        return;
    }
    
    NSURL *url = [PPOEndpointManager simplePayment:credentials.installationID
                                       withBaseURL:self.baseURL];
    
    NSMutableURLRequest *request = [self mutableJSONPostRequest:url
                                                    withTimeOut:timeout];
    
    [request setValue:[self authorisation:credentials] forHTTPHeaderField:@"Authorization"];
    
    NSData *data = [self buildPostBodyWithTransaction:payment.transaction
                                             withCard:payment.creditCard
                                          withAddress:payment.billingAddress];
    
    [request setHTTPBody:data];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:self.payments];
    
    [self resumeRequest:request forSession:session withCompletion:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        outcome = [PPOOutcomeManager handleResponse:data
                                          withError:error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(outcome);
        });
        
    }];
}

-(PPOOutcome*)validatePayment:(PPOPayment*)payment {

    return [self validateTransaction:payment.transaction
                            withCard:payment.creditCard];
    
}

-(PPOOutcome*)validateBaseURL:(NSURL*)baseURL {
    if (!baseURL) {
        return [PPOOutcomeManager handleResponse:nil
                                       withError:[PPOErrorManager errorForCode:PPOErrorSuppliedBaseURLInvalid]];
    }
    return nil;
}

-(PPOOutcome*)validateCredentials:(PPOCredentials*)credentials {
    
    if (!credentials) {
        return [PPOOutcomeManager handleResponse:nil
                                       withError:[PPOErrorManager errorForCode:PPOErrorCredentialsNotFound]];
    }
    
    if (!credentials.installationID || credentials.installationID.length == 0) {
        
        return [PPOOutcomeManager handleResponse:nil
                                       withError:[PPOErrorManager errorForCode:PPOErrorInstallationIDInvalid]];
    }
    return nil;
}

-(PPOOutcome*)validateTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card {
    
    NSString *strippedValue = [card.pan stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue.length < 13 || strippedValue.length > 19) {
        
        return [PPOOutcomeManager handleResponse:nil
                                       withError:[PPOErrorManager errorForCode:PPOErrorCardPanLengthInvalid]];
        
    }
    
    if (![PPOLuhn validateString:strippedValue]) {
        
        return [PPOOutcomeManager handleResponse:nil
                                       withError:[PPOErrorManager errorForCode:PPOErrorLuhnCheckFailed]];
    }
    
    strippedValue = [card.cvv stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length < 3 || strippedValue.length > 4) {
        
        return [PPOOutcomeManager handleResponse:nil
                                       withError:[PPOErrorManager errorForCode:PPOErrorCVVInvalid]];
    }
    
    strippedValue = [card.expiry stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length != 4) {
        
        return [PPOOutcomeManager handleResponse:nil
                                       withError:[PPOErrorManager errorForCode:PPOErrorCardExpiryDateInvalid]];
    }
    
    strippedValue = [transaction.currency stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length == 0) {
        
        return [PPOOutcomeManager handleResponse:nil
                                       withError:[PPOErrorManager errorForCode:PPOErrorCurrencyInvalid]];
    }
    
    if (transaction.amount == nil || transaction.amount.floatValue <= 0.0) {
        
        return [PPOOutcomeManager handleResponse:nil
                                       withError:[PPOErrorManager errorForCode:PPOErrorPaymentAmountInvalid]];
        
    }
    
    return nil;
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

-(NSOperationQueue *)payments {
    if (_payments == nil) {
        _payments = [NSOperationQueue new];
        _payments.name = @"Payments_Queue";
        _payments.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    }
    return _payments;
}

-(void)resumeRequest:(NSURLRequest*)request forSession:(NSURLSession*)session withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                                });
                                                
                                                completion(data, response, error);
                                                
                                            }];
    
    [task resume];
    
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    
    //    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    //    {
    //        SecTrustResultType result;
    //        //This takes the serverTrust object and checkes it against your keychain
    //        SecTrustEvaluate(challenge.protectionSpace.serverTrust, &result);
    //
    //        //If allow invalid certs, end here
    //        //completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    //
    //        //When testing this against a trusted server I got kSecTrustResultUnspecified every time. But the other two match the description of a trusted server
    //        if(result == kSecTrustResultProceed ||  result == kSecTrustResultUnspecified){
    //            completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    //        }
    //        else {
    //            //Asks the user for trust
    //            if (YES) {
    //                //May need to add a method to add serverTrust to the keychain like Firefox's "Add Excpetion"
    //                completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    //            }
    //            else {
    //                [[challenge sender] cancelAuthenticationChallenge:challenge];
    //            }
    //        }
    //    }
    //    else if ([[challenge protectionSpace] authenticationMethod] == NSURLAuthenticationMethodDefault) {
    //        NSURLCredential *newCredential = [NSURLCredential credentialWithUser:@"" password:@"" persistence:NSURLCredentialPersistenceNone];
    //        completionHandler(NSURLSessionAuthChallengeUseCredential, newCredential);
    //    }
    
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

@end

@implementation PPOEndpointManager

+(NSURL*)simplePayment:(NSString*)installationID withBaseURL:(NSURL*)baseURL {
    return [baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"/transactions/%@/payment", installationID]];
    
}

@end
