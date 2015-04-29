//
//  PPOPaymentsDispatchManager.m
//  Paypoint
//
//  Created by Robert Nash on 20/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentsDispatchManager.h"
#import "PPOPayment.h"
#import "PPOCredentials.h"
#import "PPOErrorManager.h"

@interface PPOPaymentsDispatchManager () <NSURLSessionTaskDelegate>
@property (nonatomic, strong, readwrite) NSOperationQueue *payments;
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation PPOPaymentsDispatchManager

-(NSOperationQueue *)payments {
    if (_payments == nil) {
        _payments = [NSOperationQueue new];
        _payments.name = @"Payments_Queue";
        _payments.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    }
    return _payments;
}

-(NSURLSession *)session {
    if (_session == nil) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.payments];
    }
    return _session;
}

-(void)dispatchRequest:(NSURLRequest*)request withCompletion:(void (^)(PPOOutcome *outcome, NSError *error))completion {
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSessionDataTask *task;
    
    task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
        
        id json;
        NSError *invalidJSON;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        NSError *error;
        PPOOutcome *outcome;
        
        if (invalidJSON) {
            error = [PPOErrorManager errorForCode:PPOErrorServerFailure];
        } else if (json) {
            outcome = [[PPOOutcome alloc] initWithData:json];
            if (outcome.isSuccessful == NO) {
                PPOErrorCode code = [PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue];
                error = [PPOErrorManager errorForCode:code];
            }
        } else if (networkError) {
            error = networkError;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            completion(outcome, error);
        });
        
    }];
    
    [task resume];
    
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    
}

@end
