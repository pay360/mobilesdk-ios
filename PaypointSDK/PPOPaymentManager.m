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
#import "PPOCreditCard.h"
#import "PPOLuhn.h"
#import "PPOCredentials.h"
#import "PPOTransaction.h"
#import "PPOPaymentEndpointManager.h"
#import "PPORedirect.h"
#import "PPOSDKConstants.h"
#import "PPODeviceInfo.h"
#import "PPOResourcesManager.h"
#import "PPOFinancialServices.h"
#import "PPOCustomer.h"
#import "PPOCustomField.h"
#import "PPOTimeManager.h"
#import "PPOPaymentTrackingManager.h"
#import "PPOWebFormManager.h"
#import "PPOValidator.h"
#import "PPOURLRequestManager.h"

@interface PPOPaymentManager () <NSURLSessionTaskDelegate>
@property (nonatomic, strong) PPOPaymentEndpointManager *endpointManager;
@property (nonatomic, strong) NSURLSession *internalURLSession;
@property (nonatomic, strong) NSURLSession *externalURLSession;
@property (nonatomic, strong) PPODeviceInfo *deviceInfo;
@property (nonatomic, strong) PPOWebFormManager *webFormManager;
@end

@implementation PPOPaymentManager

-(instancetype)initWithBaseURL:(NSURL*)baseURL {
    self = [super init];
    if (self) {
        _endpointManager = [[PPOPaymentEndpointManager alloc] initWithBaseURL:baseURL];
        _deviceInfo = [PPODeviceInfo new];
        NSOperationQueue *q;
        q = [NSOperationQueue new];
        q.name = @"Internal_PPO_Queue";
        q.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        _internalURLSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:q];
        q = [NSOperationQueue new];
        q.name = @"External_PPO_Queue";
        q.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        _externalURLSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:q];
    }
    return self;
}

-(void)makePayment:(PPOPayment*)payment
       withTimeOut:(NSTimeInterval)timeout
    withCompletion:(void(^)(PPOOutcome *, NSError *))completion {
    
    NSError *issue;
    
    issue = [PPOValidator validateBaseURL:self.endpointManager.baseURL];
    if (issue) {
        completion(nil, issue);
        return;
    }
    
    issue = [PPOValidator validateCredentials:payment.credentials];
    if (issue) {
        completion(nil, issue);
        return;
    }
    
    BOOL thisPaymentUnderway = [PPOPaymentTrackingManager stateForPayment:payment] != PAYMENT_STATE_NON_EXISTENT;
    
    if (thisPaymentUnderway) {
        completion(nil, [PPOErrorManager errorForCode:PPOErrorPaymentProcessing]);
        return;
    }
    
    BOOL anyPaymentUnderway = ![PPOPaymentTrackingManager allPaymentsComplete];
    
    if (anyPaymentUnderway) {
        completion(nil, [PPOErrorManager errorForCode:PPOErrorPaymentManagerOccupied]);
        return;
    }
    
    issue = [PPOValidator validatePayment:payment];
    if (issue) {
        completion(nil, issue);
        return;
    }
    
    NSURL *url = [self.endpointManager urlForSimplePayment:payment.credentials.installationID];
    
    NSData *body = [PPOURLRequestManager buildPostBodyWithPayment:payment
                                                   withDeviceInfo:self.deviceInfo];
    
    NSURLRequest *request = [PPOURLRequestManager requestWithURL:url
                                                      withMethod:@"POST"
                                                     withTimeout:60.0f
                                                       withToken:payment.credentials.token
                                                        withBody:body
                                                forPaymentWithID:payment.identifier];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    if (PPO_DEBUG_MODE) {
        NSLog(@"Making payment with op ref %@", payment.identifier);
    }
    
    NSURLSessionDataTask *task = [self.internalURLSession dataTaskWithRequest:request
                                                            completionHandler:[self networkCompletionForPayment:payment withOverallCompletion:completion]];
    
    __weak typeof(task) weakTask = task;
    [PPOPaymentTrackingManager appendPayment:payment
                                 withTimeout:timeout
                                beginTimeout:YES
                              timeoutHandler:^{
                                  [weakTask cancel];
                              }];
    
    [task resume];
    
}

-(void)queryPayment:(PPOPayment*)payment
     withCompletion:(void(^)(PPOOutcome *, NSError *))completion {
    
    NSError *issue;
    
    issue = [PPOValidator validateBaseURL:self.endpointManager.baseURL];
    if (issue) {
        completion(nil, issue);
        return;
    }
    
    issue = [PPOValidator validateCredentials:payment.credentials];
    if (issue) {
        completion(nil, issue);
        return;
    }
    
    PAYMENT_STATE state = [PPOPaymentTrackingManager stateForPayment:payment];
    
    switch (state) {
        case PAYMENT_STATE_NON_EXISTENT: {
            //There may be an empty chapperone in the tracker, because the chappereone holds the payment weakly, not strongly.
            [PPOPaymentTrackingManager removePayment:payment];
            [self queryServerForPayment:payment isInternalQuery:NO withCompletion:completion];
            return;
        }
            break;
            
        case PAYMENT_STATE_READY: {
            completion(nil, [PPOErrorManager errorForCode:PPOErrorPaymentProcessing]);
            return;
        }
            break;
            
        case PAYMENT_STATE_IN_PROGRESS: {
            completion(nil, [PPOErrorManager errorForCode:PPOErrorPaymentProcessing]);
            return;
        }
            break;
            
        case PAYMENT_STATE_SUSPENDED: {
            completion(nil, [PPOErrorManager errorForCode:PPOErrorPaymentSuspendedForThreeDSecure]);
            return;
        }
            break;
    }

}

-(void)queryServerForPayment:(PPOPayment*)payment
             isInternalQuery:(BOOL)internal
              withCompletion:(void(^)(PPOOutcome *, NSError *))completion {
    
    NSURL *url = [self.endpointManager urlForPaymentWithID:payment.identifier
                                                  withInst:payment.credentials.installationID];
    
    //The payment identifier is passed in the url.
    NSURLRequest *request = [PPOURLRequestManager requestWithURL:url
                                                      withMethod:@"GET"
                                                     withTimeout:5.0f
                                                       withToken:payment.credentials.token
                                                        withBody:nil
                                                forPaymentWithID:nil];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    id completionHandler = [self networkCompletionForQuery:payment
                                           isInternalQuery:internal
                                     withOverallCompletion:completion];
    
    NSURLSession *session = (internal) ? self.internalURLSession : self.externalURLSession;
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:completionHandler];
    
    if (internal) {
        __weak typeof(task) weakTask = task;
        [PPOPaymentTrackingManager overrideTimeoutHandler:^{
            [weakTask cancel];
        } forPayment:payment];
    }
    
    [task resume];

}

-(void(^)(NSData *, NSURLResponse *, NSError *))networkCompletionForQuery:(PPOPayment*)payment
                                                          isInternalQuery:(BOOL)internal
                                                    withOverallCompletion:(void(^)(PPOOutcome *, NSError *))completion {
    
    return ^ (NSData *data, NSURLResponse *response, NSError *networkError) {
        
        id json;
        
        NSError *invalidJSON;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        PPOOutcome *outcome;
        
        if (!networkError && json) {
            outcome = [[PPOOutcome alloc] initWithData:json];
        }
        
        NSError *e = networkError;
        
        if (!internal && outcome && outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == NO) {
            // Let's produce a customer friendly error
            // This will generate an enum for the reason code, wrapped in an NSError with a user info dictionary.
            e = [PPOErrorManager errorForCode:[PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(outcome, e);
        });

    };
}

-(void(^)(NSData *, NSURLResponse *, NSError *))networkCompletionForPayment:(PPOPayment*)payment
                                                      withOverallCompletion:(void(^)(PPOOutcome *, NSError *))completion {
    
    __weak typeof(self) weakSelf = self;
    
    return ^ (NSData *data, NSURLResponse *response, NSError *networkError) {
        
        id json;
        
        NSError *invalidJSON;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        PPORedirect *redirect;
        
        if (json) {
            redirect = [[PPORedirect alloc] initWithData:json
                                              forPayment:payment];
        }
                
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (invalidJSON) {
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [PPOPaymentTrackingManager removePayment:payment];
                completion(nil, [PPOErrorManager errorForCode:PPOErrorServerFailure]);
                
            } else if (redirect) {
                
                if (redirect.request) {
                    
                    self.webFormManager = [[PPOWebFormManager alloc] initWithRedirect:redirect
                                                                      withCredentials:payment.credentials
                                                                          withSession:self.internalURLSession
                                                                  withEndpointManager:self.endpointManager
                                                                       withCompletion:^(PPOOutcome *webFormOutcome, NSError *webFormError) {
                                                                              
                                                                           [weakSelf handleOutcome:webFormOutcome
                                                                                        forPayment:payment
                                                                                         withError:webFormError
                                                                                    withCompletion:completion];
                                                                              
                                                                          }];
                    
                } else {
                    
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    [PPOPaymentTrackingManager removePayment:payment];
                    completion(nil, [PPOErrorManager errorForCode:PPOErrorProcessingThreeDSecure]);
                    
                }
                
            } else if (json) {
                
                PPOOutcome *outcome = [[PPOOutcome alloc] initWithData:json];
                
                [weakSelf handleOutcome:outcome
                             forPayment:payment
                              withError:networkError
                         withCompletion:completion];
                
            } else if (networkError) {
                
                [weakSelf handleOutcome:nil
                             forPayment:payment
                              withError:networkError
                         withCompletion:completion];
                
            } else {
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [PPOPaymentTrackingManager removePayment:payment];
                completion(nil, [PPOErrorManager errorForCode:PPOErrorUnknown]);
                
            }
            
        });
        
    };
    
}

-(void)handleOutcome:(PPOOutcome*)outcome
          forPayment:(PPOPayment*)payment
           withError:(NSError*)networkError
      withCompletion:(void(^)(PPOOutcome *, NSError*))completion {
    
    // Here we handle the final outcome
    
    // The error manager will parse the appropriate customer facing code
    // e.g. if we parse reason code 'Suspended for 3DS' we generate PPOErrorTransactionProcessingFailed
    
    PPOErrorCode code = PPOErrorNotInitialised;
    
    if (outcome && outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == NO) {
        code = [PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue];
    }
    
    if (code == PPOErrorPaymentProcessing || (networkError && networkError.code != NSURLErrorCancelled)) {
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Not sure if payment made it for op ref: %@", payment.identifier);
            
            NSLog(@"Yo server, what's going on with payment for op ref %@", payment.identifier);
        }
        
        __weak typeof(self) weakSelf = self;
        
        [self queryServerForPayment:payment isInternalQuery:YES withCompletion:^(PPOOutcome *queryOutcome, NSError *queryError) {
            
            // Recursively call ourselves. The implementing SDK developer session timeout countdown will
            // abort this recursion, if we do not get a conclusion
            
            [weakSelf handleOutcome:queryOutcome
                         forPayment:payment
                          withError:queryError
                     withCompletion:completion];
            
        }];
        
    } else {
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Got a conclusion. Let's dance.");
        }
        
        NSError *e = networkError;
        
        if (networkError.code == NSURLErrorCancelled) {
            e = [PPOErrorManager errorForCode:PPOErrorSessionTimedOut];
        } else {
            e = [PPOErrorManager errorForCode:code];
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [PPOPaymentTrackingManager removePayment:payment];
        completion(outcome, e);
        
    }
    
}

@end
