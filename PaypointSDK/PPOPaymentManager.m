//
//  PPOPaymentManager.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentManager.h"
#import "PPOEndpointManager.h"
#import "PPOCreditCard.h"
#import "PPOCredentials.h"
#import "PPOTransaction.h"
#import "PPOBillingAddress.h"
#import "PPOErrorManager.h"
#import "PPOLuhn.h"

@interface PPOPaymentManager () <NSURLSessionTaskDelegate>
@property (nonatomic, strong, readwrite) NSOperationQueue *payments;
@end

@implementation PPOPaymentManager

-(instancetype)initWithCredentials:(PPOCredentials*)credentials withDelegate:(id<PPOPaymentManagerDelegate>)delegate {
    self = [super init];
    if (self) {
        _credentials = credentials;
        _delegate = delegate;
    }
    return self;
}

-(void)makePaymentWithTransaction:(PPOTransaction*)transaction forCard:(PPOCreditCard*)card withBillingAddress:(PPOBillingAddress*)billingAddress {
    
    if (![PPOLuhn validateString:card.pan]) {
        
        NSError *paypointError = [NSError errorWithDomain:PaypointSDKDomain
                                                     code:PPOErrorLuhnCheckFailed
                                                 userInfo:@{
                                                            NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Luhn check failed", @"Failure message for a failed Luhn check")
                                                            }
                                  ];
        
        [self.delegate paymentFailed:paypointError];
        
        return;
    }
    
    NSMutableURLRequest *request = [self mutableJSONPostRequest:[PPOEndpointManager simplePayment:self.credentials.installationID]];
    [request setValue:[self authorisation:self.credentials] forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:[self buildPostBodyWithTransaction:transaction withCard:card withAddress:billingAddress]];
    
    __weak typeof (self) weakSelf = self;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.payments];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {

            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate paymentFailed:error];
            });
            
            return;
        }
        
        [weakSelf parsePaypointData:data error:error httpStatusCode:((NSHTTPURLResponse*)response).statusCode];
        
    }];
    
    [task resume];
}

- (void)parsePaypointData:(NSData *)data error:(NSError *)error httpStatusCode:(NSInteger)httpStatusCode {
    
    NSString *reasonMessage;
    NSNumber *reasonCode = @(PPOErrorUnknown);
    NSError *paypointError;
    
    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    id outcome = [json objectForKey:@"outcome"];
    if ([outcome isKindOfClass:[NSDictionary class]]) {
        
        id value;
        
        value = [outcome objectForKey:@"reasonCode"];
        if ([value isKindOfClass:[NSNumber class]]) {
            reasonCode = value;
        }
        value = [outcome objectForKey:@"reasonMessage"];
        if ([value isKindOfClass:[NSNumber class]]) {
            reasonMessage = value;
        }
        
        if (reasonCode.integerValue > 0) {
            
            NSMutableDictionary *mutableUserInfo;
            
            if (reasonMessage) {
                mutableUserInfo = [NSMutableDictionary new];
                [mutableUserInfo setValue:reasonMessage forKey:NSLocalizedFailureReasonErrorKey];
            }
            
            paypointError = [NSError errorWithDomain:[PPOErrorManager errorDomainForReasonCode:reasonCode.integerValue]
                                                code:[PPOErrorManager errorCodeForReasonCode:reasonCode.integerValue]
                                            userInfo:[mutableUserInfo copy]];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (paypointError) {
            [self.delegate paymentFailed:paypointError];
        } else {
            [self.delegate paymentSucceeded:reasonMessage];
        }
    });
}

-(NSMutableURLRequest*)mutableJSONPostRequest:(NSURL*)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    return request;
}

-(NSString*)authorisation:(PPOCredentials*)credentials {
    return [NSString stringWithFormat:@"Bearer %@", credentials.token];
}

-(NSData*)buildPostBodyWithTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card withAddress:(PPOBillingAddress*)address {
    
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

#pragma mark - NSURLSessionDataTaskProtocol

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    NSLog(@"%@ NSURLSession didReceiveChallenge: %@", [self class], challenge);
    
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
