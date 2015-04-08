//
//  PPOPaymentManager.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentManager.h"
#import "PPOEndpointManager.h"

@interface PPOPaymentManager () <NSURLSessionTaskDelegate>
@property (nonatomic, strong, readwrite) NSOperationQueue *payments;
@property (nonatomic, strong) PPOCredentials *credentials;
@end

@implementation PPOPaymentManager

-(instancetype)initWithCredentials:(PPOCredentials*)credentials {
    self = [super init];
    if (self) {
        _credentials = credentials;
    }
    return self;
}

-(void)startTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card forAddress:(PPOBillingAddress*)address completionHandler:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    
    NSMutableURLRequest *request = [self mutableJSONPostRequest:[PPOEndpointManager simplePayment:self.credentials.installationID]];
    [request setValue:[self authorisation:self.credentials] forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:[self buildPostBodyWithTransaction:transaction withCard:card withAddress:address]];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.payments];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:completion];
    [task resume];
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
    
    id object = @{
                  @"transaction": [transaction jsonObjectRepresentation],
                  @"paymentMethod": @{
                                        @"card": [card jsonObjectRepresentation],
                                        @"billingAddress": [address jsonObjectRepresentation]
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
