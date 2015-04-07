//
//  PPOPaymentManager.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentManager.h"
#import "PPOEndpoint.h"

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
    
    NSMutableURLRequest *request = [self mutableJSONPostRequest:[PPOEndpoint simplePayment:self.credentials.installationID]];
    [request setValue:[self authorisation:self.credentials] forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:[self buildPostBodyWithTransaction:transaction withCard:card withAddress:address]];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.payments];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:completion];
    [task resume];
}

-(NSMutableURLRequest*)mutableJSONPostRequest:(NSURL*)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    return request;
}

-(NSString*)authorisation:(PPOCredentials*)credentials {
    return [NSString stringWithFormat:@"Bearer %@", credentials.token];
}

-(NSData*)buildPostBodyWithTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card withAddress:(PPOBillingAddress*)address {
    
    id object = @{
                  @"transaction": [transaction jsonObjectRepresentation],
                  @"paymentMethod": @{@"card": [card jsonObjectRepresentation]},
                  @"billingAddress": [address jsonObjectRepresentation]
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

@end
