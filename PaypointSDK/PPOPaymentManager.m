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
#import "PPOCard.h"
#import "PPOLuhn.h"
#import "PPOCredentials.h"
#import "PPOTransaction.h"
#import "PPOPaymentEndpointManager.h"
#import "PPORedirect.h"
#import "PPOSDKConstants.h"
#import "PPODeviceInfo.h"
#import "PPOResourcesManager.h"
#import "PPOFinancialService.h"
#import "PPOCustomer.h"
#import "PPOCustomField.h"
#import "PPOTimeManager.h"
#import "PPOPaymentTrackingManager.h"
#import "PPORedirectManager.h"
#import "PPOValidator.h"
#import "PPOOutcomeBuilder.h"
#import "PPOURLRequestManager.h"

@interface PPOPaymentManager () <NSURLSessionTaskDelegate>
@property (nonatomic, strong) PPOPaymentEndpointManager *endpointManager;
@property (nonatomic, strong) NSURLSession *internalURLSession;
@property (nonatomic, strong) NSURLSession *externalURLSession;
@property (nonatomic, strong) PPODeviceInfo *deviceInfo;
@property (nonatomic, strong) PPORedirectManager *redirectManager;
@property (nonatomic, strong) dispatch_queue_t q_queue;
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

+(BOOL)isSafeToRetryPaymentWithOutcome:(PPOOutcome *)outcome {
    
    if (!outcome) return NO;
    
    NSError *error = outcome.error;
    
    if (!error) return NO;
    
    return [PPOErrorManager isSafeToRetryPaymentWithError:error];
    
}

-(void)makePayment:(PPOPayment*)payment
       withTimeOut:(NSTimeInterval)timeout
    withCompletion:(void(^)(PPOOutcome *))completion {
    
    PPOOutcome *outcome;
    NSError *error;
    
    error = [PPOValidator validateBaseURL:self.endpointManager.baseURL];
    if (error) {
        outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                           withError:error
                                          forPayment:payment];
        [self handleOutcome:outcome
             withCompletion:completion];
        return;
    }
    
    error = [PPOValidator validateCredentials:payment.credentials];
    if (error) {
        outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                           withError:error
                                          forPayment:payment];
        [self handleOutcome:outcome
             withCompletion:completion];
        return;
    }
    
    BOOL thisPaymentUnderway = [PPOPaymentTrackingManager stateForPayment:payment] != PAYMENT_STATE_NON_EXISTENT;
    
    if (thisPaymentUnderway) {
        error = [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorPaymentProcessing];
        outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                           withError:error
                                          forPayment:payment];
        [self handleOutcome:outcome
             withCompletion:completion];
        return;
    }
    
    /*
     * PPOPaymentTrackingManager can handle multiple payments, for future proofing.
     * However, SDK forces one payment at a time (see error description PPOErrorPaymentManagerOccupied)
     */
    BOOL anyPaymentUnderway = ![PPOPaymentTrackingManager allPaymentsComplete];
    
    if (anyPaymentUnderway) {
        error = [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorPaymentManagerOccupied];
        outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                           withError:error
                                          forPayment:payment];
        [self handleOutcome:outcome
             withCompletion:completion];
        return;
    }
    
    error = [PPOValidator validatePayment:payment];
    if (error) {
        outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                           withError:error
                                          forPayment:payment];
        [self handleOutcome:outcome
             withCompletion:completion];
        return;
    }
    
    NSURL *url = [self.endpointManager urlForSimplePayment:payment.credentials.installationID];
    
#if PPO_DEBUG_MODE
    NSLog(@"Making payment with op ref %@", payment.identifier);
    NSLog(@"URL to be used for payment: %@", url);
#endif
    
    NSData *body = [PPOURLRequestManager buildPostBodyWithPayment:payment
                                                   withDeviceInfo:self.deviceInfo];
    
    NSURLRequest *request = [PPOURLRequestManager requestWithURL:url
                                                      withMethod:@"POST"
                                                     withTimeout:60.0f
                                                       withToken:payment.credentials.token
                                                        withBody:body
                                                forPaymentWithID:payment.identifier];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

#if PPO_DEBUG_MODE
    NSLog(@"Making payment with op ref %@", payment.identifier);
#endif
    
    id completionHandler = [self networkCompletionForPayment:payment
                                       withOverallCompletion:completion];
    
    NSURLSessionDataTask *task = [self.internalURLSession dataTaskWithRequest:request
                                                            completionHandler:completionHandler];
    
    __weak typeof(task) weakTask = task;
    [PPOPaymentTrackingManager appendPayment:payment
                                 withTimeout:timeout
                                beginTimeout:YES
                              timeoutHandler:^{
                                  [weakTask cancel];
                              }];
    
    [task resume];

}

/*
 * The implementing developer may call this if he/she wants to discover the state of a payment
 * that is currently underway, or a historic payment. This call may happen whilst the SDK is busy
 * handling a payment. The primary reason for distinguishing internal and external,
 * queries is to ensure that the master session timeout handler only cancels networking tasks that are 
 * associated with an ongoing payment. The secondary reason is so that we can assign network tasks to one 
 * of two dedicated NSURLSession instances. This allows for a cancel feature, should we want to implement 
 * that feature in the future.
 */
-(void)queryPayment:(PPOPayment*)payment
     withCompletion:(void(^)(PPOOutcome *))completion {
    
    NSError *error;
    PPOOutcome *outcome;
    
    error = [PPOValidator validateBaseURL:self.endpointManager.baseURL];
    if (error) {
        outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                           withError:error
                                          forPayment:payment];
        [self handleOutcome:outcome
             withCompletion:completion];
        return;
    }
    
    error = [PPOValidator validateCredentials:payment.credentials];
    if (error) {
        outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                           withError:error
                                          forPayment:payment];
        [self handleOutcome:outcome
             withCompletion:completion];
        return;
    }
    
    switch ([PPOPaymentTrackingManager stateForPayment:payment]) {
            
        case PAYMENT_STATE_NON_EXISTENT: {
            
            /*
             * There may be an empty chapperone in the tracker, because the chappereone holds the payment weakly, not strongly.
             * This may happen if the entire SDK is deallocated during a payment (tracker is singleton).
             * Not essential, but worth clean up as is possible (main reason why payment is weak).
             */
            [PPOPaymentTrackingManager removePayment:payment];
            
            [self queryServerForPayment:payment
                        isInternalQuery:NO
                         withCompletion:completion];
            return;
        }
            break;
            
        case PAYMENT_STATE_READY: {
            error = [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorPaymentProcessing];
            outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                               withError:error
                                              forPayment:payment];
            [self handleOutcome:outcome
                 withCompletion:completion];
            return;
        }
            break;
            
        case PAYMENT_STATE_IN_PROGRESS: {
            error = [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorPaymentProcessing];
            outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                               withError:error
                                              forPayment:payment];
            [self handleOutcome:outcome
                 withCompletion:completion];
            return;
        }
            break;
            
        case PAYMENT_STATE_SUSPENDED: {
            error = [PPOErrorManager buildErrorForPrivateErrorCode:PPOPrivateErrorPaymentSuspendedForThreeDSecure];
            outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                               withError:error
                                              forPayment:payment];
            [self handleOutcome:outcome
                 withCompletion:completion];
            return;
        }
            break;
    }

}

/*
 * The SDK may call this method to determine the state of a payment and establish an outcome.
 * If the outcome is 'still processing' or we suffered with a network interuption, then the 
 * SDK will call this method recursively, until a more conclusive outcome is established
 * or the master session timeout timer fires.
 */
-(void)queryServerForPayment:(PPOPayment*)payment
             isInternalQuery:(BOOL)internalQuery
              withCompletion:(void(^)(PPOOutcome *))completion {
    
    /*
     * The payment identifier is passed as a component in the url;
     */
    NSURL *url = [self.endpointManager urlForPaymentWithID:payment.identifier
                                                  withInst:payment.credentials.installationID];
    
    /*
     * The payment identifier is deliberately not passed as a header here.
     */
    NSURLRequest *request = [PPOURLRequestManager requestWithURL:url
                                                      withMethod:@"GET"
                                                     withTimeout:5.0f
                                                       withToken:payment.credentials.token
                                                        withBody:nil
                                                forPaymentWithID:nil];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    id completionHandler = [self networkCompletionForQuery:payment
                                           isInternalQuery:internalQuery
                                     withOverallCompletion:completion];
    
    /*
     * If the SDK is trying to establish a more conclusive outcome for a payment, then internalQuery is set to 'YES' here.
     */
    NSURLSession *session = (internalQuery) ? self.internalURLSession : self.externalURLSession;
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:completionHandler];
    
    /*
     * Cancelling the task like this triggers an NSURL 'cancel' in the network completion handler.
     */
    if (internalQuery) {
        __weak typeof(task) weakTask = task;
        
        [PPOPaymentTrackingManager overrideTimeoutHandler:^{
            
            
#if PPO_DEBUG_MODE
    NSLog(@"Cancelling internal query with task %@", weakTask);
#endif
            
            [weakTask cancel];
            
        } forPayment:payment];
    }
    
    [task resume];

}

-(void(^)(NSData *, NSURLResponse *, NSError *))networkCompletionForQuery:(PPOPayment*)payment
                                                          isInternalQuery:(BOOL)isInternal
                                                    withOverallCompletion:(void(^)(PPOOutcome *))completion {
    
    return ^ (NSData *data, NSURLResponse *response, NSError *networkError) {
        
        id json;
        
        NSError *invalidJSON;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        PPOOutcome *outcome;
        
        if (!networkError && json) {
            outcome = [PPOOutcomeBuilder outcomeWithData:json
                                               withError:nil
                                              forPayment:payment];
        } else if (networkError) {
            
            /*
             * Potentially 'NSURLErrorCancel', if the master session timeout fired.
             */
            outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                               withError:networkError
                                              forPayment:payment];
        }
        
        if (isInternal == NO) {

#if PPO_DEBUG_MODE
    NSLog(@"EXTERNAL QUERY: Established error with domain: %@ with code: %li", outcome.error.domain, (long)outcome.error.code);
#endif
            
            outcome.error = [PPOErrorManager buildCustomerFacingErrorFromError:outcome.error];
            
#if PPO_DEBUG_MODE
    NSLog(@"EXTERNAL QUERY: Converted error to customer friendly error with domain: %@ with code: %li", outcome.error.domain, (long)outcome.error.code);
#endif
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            completion(outcome);
        });

    };
}

-(void(^)(NSData *, NSURLResponse *, NSError *))networkCompletionForPayment:(PPOPayment*)payment
                                                      withOverallCompletion:(void(^)(PPOOutcome *))completion {
    
    __weak typeof(self) weakSelf = self;
    
    return ^ (NSData *data, NSURLResponse *response, NSError *networkError) {
        
        id json;
        
        NSError *invalidJSON;
        
        if (data.length > 0) {
            
            json = [NSJSONSerialization JSONObjectWithData:data
                                                   options:NSJSONReadingAllowFragments
                                                     error:&invalidJSON];
            
        }
        
        PPORedirect *redirect;
        
        if ([PPORedirect requiresRedirect:json]) {
            
            redirect = [[PPORedirect alloc] initWithData:json
                                              forPayment:payment];
            
        }
                
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            if (invalidJSON) {
                
                [PPOPaymentTrackingManager removePayment:payment];
                
                PPOOutcome *outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                                               withError:[PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorServerFailure]
                                                              forPayment:payment];
                completion(outcome);
                
            } else if (redirect) {
                
                [weakSelf performRedirect:redirect
                           withCompletion:completion];
                
            } else if (json) {
                
                PPOOutcome *outcome = [PPOOutcomeBuilder outcomeWithData:json
                                                               withError:nil
                                                              forPayment:payment];
                
                [weakSelf handleOutcome:outcome
                         withCompletion:completion];
                
            } else if (networkError) {
                
                PPOOutcome *outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                                               withError:networkError
                                                              forPayment:payment];
                
                [weakSelf handleOutcome:outcome
                         withCompletion:completion];
                
            } else {
                
                PPOOutcome *outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                                               withError:[PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorUnexpected]
                                                              forPayment:payment];
                
                [PPOPaymentTrackingManager removePayment:payment];
                
                completion(outcome);
                
            }
            
        });
        
    };
    
}

-(void)performRedirect:(PPORedirect*)redirect
        withCompletion:(void(^)(PPOOutcome*))completion {
    
    if (redirect.request) {
        
        __weak typeof(self) weakSelf = self;
        
        self.redirectManager = [[PPORedirectManager alloc] initWithRedirect:redirect
                                                                withSession:self.internalURLSession
                                                        withEndpointManager:self.endpointManager
                                                             withCompletion:^(PPOOutcome *outcome) {
                                                               
                                                                 [weakSelf handleOutcome:outcome
                                                                          withCompletion:completion];
                                                               
                                                             }];
        
        [self.redirectManager startRedirect];
        
    } else {
        
        [PPOPaymentTrackingManager removePayment:redirect.payment];
        
        PPOOutcome *outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                                       withError:[PPOErrorManager buildErrorForPrivateErrorCode:PPOPrivateErrorProcessingThreeDSecure]
                                                      forPayment:redirect.payment];
        
        [self handleOutcome:outcome
             withCompletion:completion];
        
    }
    
}

-(void)handleOutcome:(PPOOutcome*)outcome
      withCompletion:(void(^)(PPOOutcome *))completion {
    
    BOOL isNetworkingIssue = [outcome.error.domain isEqualToString:NSURLErrorDomain];
    BOOL sessionTimedOut = isNetworkingIssue && outcome.error.code == NSURLErrorCancelled;
    BOOL isProcessingAtPaypoint = [outcome.error.domain isEqualToString:PPOPaymentErrorDomain] && outcome.error.code == PPOPaymentErrorPaymentProcessing;
    
    if ((isNetworkingIssue && !sessionTimedOut) || isProcessingAtPaypoint) {
        
        [self attemptToEstablishAMoreConclusiveOutcome:outcome
                                        withCompletion:completion];
        
    }
    else {
    
#if PPO_DEBUG_MODE
    NSLog(@"Got a conclusion.");
#endif
        
        outcome.error = [PPOErrorManager buildCustomerFacingErrorFromError:outcome.error];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [PPOPaymentTrackingManager removePayment:outcome.payment];
        completion(outcome);
        
    }
    
}

-(void)attemptToEstablishAMoreConclusiveOutcome:(PPOOutcome*)outcome
                                 withCompletion:(void(^)(PPOOutcome *))completion {
    
    /*
     * Before we query the server, we back off for a while by sleeping the thread.
     * We may call this method recursively, if continue to get an unsatisfactory outcome.
     */
    
    PPOPayment *payment = outcome.payment;
    
    
#if PPO_DEBUG_MODE
    NSLog(@"The outcome is not satisfactory");
    
    NSLog(@"A query is being prepared for payment with op ref %@", payment.identifier);
#endif
    
    NSUInteger attemptCount = [PPOPaymentTrackingManager totalQueryPaymentAttemptsForPayment:payment];
    NSTimeInterval interval = [PPOPaymentTrackingManager timeIntervalForAttemptCount:attemptCount];
    
    [PPOPaymentTrackingManager incrementQueryPaymentAttemptCountForPayment:payment];
    
    /*
     * A dedicated queue is used, for the sole purposes of calling 'sleep', to avoid sleeping the main queue.
     * There is an edge case where the master session timeout might fire, whilst q_queue is sleeping.
     * In this case the master session timeout handler is inspected before we commit to a query.
     */
    if (self.q_queue == nil) {
        self.q_queue = dispatch_queue_create("QueryQ", NULL);
    }
    
    void(^block)(void) = [self sleepBeforeQueryingPayment:payment
                                         forSleepInterval:interval
                                           withCompletion:completion];
    
    dispatch_async(self.q_queue, block);
    
}

-(void(^)(void))sleepBeforeQueryingPayment:(PPOPayment*)payment
                          forSleepInterval:(NSTimeInterval)interval
                            withCompletion:(void(^)(PPOOutcome*))completion {
    
    __weak typeof(self) weakSelf = self;
    
    return ^ {
        
#if PPO_DEBUG_MODE
        NSString *message = (interval == 1) ? @"second" : @"seconds";
        NSLog(@"The query will take a nap for %f %@ before heading to the server", interval, message);
#endif
        
        sleep(interval);
        
        dispatch_async(dispatch_get_main_queue(), ^{

#if PPO_DEBUG_MODE
    NSLog(@"The query just woke up and jumped on the main queue");
#endif
            
            if (![PPOPaymentTrackingManager paymentIsBeingTracked:payment] || [PPOPaymentTrackingManager masterSessionTimeoutHasExpiredForPayment:payment]) {
                
                PPOOutcome *outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                                               withError:[PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorMasterSessionTimedOut]
                                                              forPayment:payment];
                
                [weakSelf handleOutcome:outcome
                         withCompletion:completion];
                
            } else {
                
#if PPO_DEBUG_MODE
    NSLog(@"Query is heading to the server now.");
#endif
                
                [weakSelf queryServerForPayment:payment
                                isInternalQuery:YES
                                 withCompletion:^(PPOOutcome *queryOutcome) {
                                 
                                     [weakSelf handleOutcome:queryOutcome
                                              withCompletion:completion];
                                 
                                 }];
            }
            
        });
        
    };
    
}

@end
