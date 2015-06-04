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
@property (nonatomic, strong) PPOCredentials *credentials;
@property (nonatomic, strong) NSURLSession *paymentSession;
@property (nonatomic, strong) NSURLSession *querySession;
@property (nonatomic, strong) PPODeviceInfo *deviceInfo;
@property (nonatomic, strong) PPOWebFormManager *webFormManager;
@property (nonatomic, strong) NSTimer *pollingTimer;
@end

@implementation PPOPaymentManager

-(instancetype)initWithBaseURL:(NSURL*)baseURL {
    self = [super init];
    if (self) {
        _endpointManager = [[PPOPaymentEndpointManager alloc] initWithBaseURL:baseURL];
        _deviceInfo = [PPODeviceInfo new];
        [self buildPaymentSesssion];
        [self buildQuerySession];
    }
    return self;
}

-(void)buildPaymentSesssion {
    NSOperationQueue *q;
    q = [NSOperationQueue new];
    q.name = @"Payments_Queue";
    q.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    self.paymentSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:q];
}

-(void)buildQuerySession {
    NSOperationQueue *q;
    q = [NSOperationQueue new];
    q.name = @"Payments_Queue";
    q.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    self.querySession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:q];
}

-(NSUInteger)trackerCount {
    return [PPOPaymentTrackingManager currentTrackCount];
}

-(void)makePayment:(PPOPayment*)payment
   withCredentials:(PPOCredentials*)credentials
       withTimeOut:(NSTimeInterval)timeout
    withCompletion:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    
    self.credentials = credentials;
    
    if ([PPOValidator baseURLInvalid:self.endpointManager.baseURL withHandler:outcomeHandler]) return;
    if ([PPOValidator credentialsInvalid:credentials withHandler:outcomeHandler]) return;
    if ([PPOValidator paymentUnderway:payment withHandler:outcomeHandler]) return;
        
    if (![PPOPaymentTrackingManager allPaymentsComplete]) {
        outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorPaymentManagerOccupied]);
        return;
    }
    
    if ([PPOValidator paymentInvalid:payment withHandler:outcomeHandler]) return;
    
    NSURL *url = [self.endpointManager urlForSimplePayment:credentials.installationID];
    
    NSData *body = [PPOURLRequestManager buildPostBodyWithPayment:payment
                                                   withDeviceInfo:self.deviceInfo];
    
    NSURLRequest *request = [PPOURLRequestManager requestWithURL:url
                                                      withMethod:@"POST"
                                                     withTimeout:30.0f
                                                       withToken:credentials.token
                                                        withBody:body
                                                forPaymentWithID:payment.identifier];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    id completion = [self transactionResponseHandlerForPayment:payment withOutcomeHandler:outcomeHandler isQuery:NO];
    
    if (!self.paymentSession) {
        [self buildPaymentSesssion];
    }
    
    NSURLSessionDataTask *task = [self.paymentSession dataTaskWithRequest:request
                                                        completionHandler:completion];
    
    [task resume];
    
    __weak typeof(self) weakSelf = self;
    [PPOPaymentTrackingManager appendPayment:payment
                                 withTimeout:timeout
                  commenceTimeoutImmediately:YES
                              timeoutHandler:^{
                                  [weakSelf.pollingTimer invalidate];
                                  [weakSelf.paymentSession invalidateAndCancel];
                                  weakSelf.paymentSession = nil;
                                  [PPOPaymentTrackingManager removePayment:payment];
                              } withOutcomeHandler:outcomeHandler];
    
}

-(void)paymentOutcome:(PPOPayment*)payment
      withCredentials:(PPOCredentials*)credentials
       withCompletion:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    
    self.credentials = credentials;
    
    if ([PPOValidator baseURLInvalid:self.endpointManager.baseURL withHandler:outcomeHandler]) return;
    if ([PPOValidator credentialsInvalid:credentials withHandler:outcomeHandler]) return;
    
    PAYMENT_STATE state = [PPOPaymentTrackingManager stateForPayment:payment];
    
    switch (state) {
        case PAYMENT_STATE_NON_EXISTENT: {
            //There may be an empty chapperone in the tracker, because the chappereone holds the payment weakly, not strongly.
            [PPOPaymentTrackingManager removePayment:payment];
            [self queryPayment:payment withCredentials:credentials withOutcomeHandler:outcomeHandler];
            return;
        }
            break;
            
        case PAYMENT_STATE_READY: {
            outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorPaymentReadyNotStarted]);
            return;
        }
            break;
            
        case PAYMENT_STATE_IN_PROGRESS: {
            outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorPaymentProcessing]);
            return;
        }
            break;
            
        case PAYMENT_STATE_SUSPENDED: {
            outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorPaymentSuspendedForThreeDSecure]);
            return;
        }
            break;
    }

}

-(void)queryPayment:(PPOPayment*)payment
    withCredentials:(PPOCredentials*)credentials
 withOutcomeHandler:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    
    NSLog(@"Query payment");
    
    //The payment identifier is passed in the url here, not as a header.
    NSURL *url = [self.endpointManager urlForPaymentWithID:payment.identifier
                                                  withInst:credentials.installationID];
    
    NSURLRequest *request = [PPOURLRequestManager requestWithURL:url
                                                      withMethod:@"GET"
                                                     withTimeout:5.0f
                                                       withToken:credentials.token
                                                        withBody:nil
                                                forPaymentWithID:nil];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    id completion = [self transactionResponseHandlerForPayment:payment withOutcomeHandler:outcomeHandler isQuery:YES];
    
    NSURLSessionDataTask *task = [self.querySession dataTaskWithRequest:request
                                                      completionHandler:completion];
    
    [task resume];

}

-(void(^)(NSData *, NSURLResponse *, NSError *))transactionResponseHandlerForPayment:(PPOPayment*)payment
                                                                  withOutcomeHandler:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler
                                                                             isQuery:(BOOL)query {
    
    __weak typeof(self) weakSelf = self;
    
    return ^ (NSData *data, NSURLResponse *response, NSError *networkError) {
        
        id json;
        
        NSError *invalidJSON;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        id redirectData = [weakSelf redirectData:json];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (invalidJSON) {
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                if (!query) [PPOPaymentTrackingManager removePayment:payment];
                outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorServerFailure]);
                
            } else if (redirectData) {
                
                NSLog(@"redirect data found");

                if (query) {
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorTransactionProcessingFailed]);
                    [PPOPaymentTrackingManager removePayment:payment];
                } else {
                    
                    NSError *redirectError;
                    
                    redirectError = [weakSelf performSecureRedirect:redirectData forPayment:payment withOutcomeHandler:outcomeHandler];
                    
                    if (redirectError) {
                        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                        [PPOPaymentTrackingManager removePayment:payment];
                        outcomeHandler(nil, redirectError);
                    }
                }
                
                
            } else if (json) {
                
                PPOOutcome *outcome = [[PPOOutcome alloc] initWithData:json];
                
                [weakSelf handleOutcome:outcome
                             forPayment:payment
                        forNetworkError:networkError
                             forHandler:outcomeHandler
                                isQuery:query];
                
            } else if (networkError) {
                if ([PPOPaymentManager noNetwork:networkError]) {
                    [weakSelf pollStatusOfPayment:payment];
                } else if ([networkError.domain isEqualToString:NSURLErrorDomain] && networkError.code == NSURLErrorCancelled) {
                    outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorSessionTimedOut]);
                } else {
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    if (!query) [PPOPaymentTrackingManager removePayment:payment];
                    outcomeHandler(nil, networkError);
                }
            } else {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                if (!query) [PPOPaymentTrackingManager removePayment:payment];
                outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorUnknown]);
            }
        });
        
    };
    
}

-(NSDictionary*)redirectData:(id)json {

    NSString *transactionID;
    
    id value = [json objectForKey:@"transaction"];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        transactionID = [value objectForKey:@"transactionId"];
    }
    
    value = [json objectForKey:@"threeDSRedirect"];
    
    if ([value isKindOfClass:[NSDictionary class]] && [transactionID isKindOfClass:[NSString class]] && transactionID.length) {
        NSMutableDictionary *mutable = [value mutableCopy];
        [mutable setObject:transactionID forKey:@"transactionId"];
        return [mutable copy];
    }
    
    return nil;
}

-(NSError*)performSecureRedirect:(NSDictionary*)data forPayment:(PPOPayment*)payment withOutcomeHandler:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    
    NSLog(@"building redirect");
    
    PPORedirect *redirect = [[PPORedirect alloc] initWithData:data];
    redirect.transactionID = [data objectForKey:@"transactionId"];
    redirect.payment = payment;
    if (!redirect.request) {
        NSLog(@"failed building redirect");
        return [PPOErrorManager errorForCode:PPOErrorProcessingThreeDSecure];
    }
    
    NSLog(@"building webform");
    
    __weak typeof(self) weakSelf = self;
    
    PPOWebFormManager *webFormManager = [[PPOWebFormManager alloc] initWithRedirect:redirect
                                                                    withCredentials:self.credentials
                                                                        withSession:self.paymentSession
                                                                withEndpointManager:self.endpointManager
                                                                        withOutcome:^(PPOOutcome *outcome, NSError *error) {
                                                                            
                                                                            NSLog(@"Error: %@", error);
                                                                            NSNumber *timeoutOut = [PPOPaymentTrackingManager remainingSessionTimeoutForPayment:payment];
                                                                            NSLog(@"%@", timeoutOut);
                                                                            
                                                                            [weakSelf handleOutcome:outcome
                                                                                         forPayment:payment
                                                                                    forNetworkError:error
                                                                                         forHandler:outcomeHandler
                                                                                            isQuery:NO];
                                                                            return;
                                                                            if (redirect.threeDSecureResumeBody && error) {
                                                                                
                                                                                [PPOPaymentTrackingManager removePayment:payment];
                                                                                outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorTransactionProcessingFailed]);
                                                                                
                                                                            } else {
                                                                                
                                                                            }
                                                                            
                                                                        }];
    
    self.webFormManager = webFormManager;
    
    return nil;
}

-(void)handleOutcome:(PPOOutcome*)outcome forPayment:(PPOPayment*)payment forNetworkError:(NSError*)error forHandler:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler isQuery:(BOOL)query {
    
    NSLog(@"handling outcome, %@", outcome);
    NSError *e;
    
    PPOErrorCode code = PPOErrorNotInitialised;
    
    if (outcome && outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == NO) {
        code = [PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue];
        e = [PPOErrorManager errorForCode:code];
    }
    
    if (!e) {
        e = error;
    }
    

    if (self.pollingTimer && ((outcome.isSuccessful.boolValue == YES) || (code != PPOErrorPaymentProcessing && code != PPOErrorNotInitialised))) {
        
        if ([self.pollingTimer isValid]) {
            NSLog(@"invaliding polling timer");
            [self.pollingTimer invalidate];
        }
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (!query) [PPOPaymentTrackingManager removePayment:payment];
        if (outcomeHandler) {
            outcomeHandler(outcome, e);
        } else {
            NSLog(@"outcomeHandler missing");
        }
        
    } else if ([PPOPaymentManager noNetwork:e] || code == PPOErrorPaymentProcessing) {
        if (![self.pollingTimer isValid]) {
            [self pollStatusOfPayment:payment];
        }
    } else if (![self.pollingTimer isValid]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (!query) [PPOPaymentTrackingManager removePayment:payment];
        if (outcomeHandler) {
            outcomeHandler(outcome, e);
        } else {
            NSLog(@"outcomeHandler missing");
        }
        
    }
    
}

-(void)pollStatusOfPayment:(PPOPayment*)payment {
    
    if (!payment) return;
    
    NSNumber *sessionTimeoutInterval = [PPOPaymentTrackingManager remainingSessionTimeoutForPayment:payment];
    
    NSLog(@"remaining session time: %@", sessionTimeoutInterval);
    
    if (sessionTimeoutInterval) {
        
        CGFloat time = sessionTimeoutInterval.floatValue;
        
        CGFloat attemptCount = 10;
        
        CGFloat interval = time / attemptCount;
        
        self.pollingTimer = [NSTimer timerWithTimeInterval:interval
                                                    target:self
                                                  selector:@selector(statusOfPayment:)
                                                  userInfo:@{@"PaymentKey" : payment}
                                                   repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:self.pollingTimer forMode:NSDefaultRunLoopMode];
    }
    
}

-(void)statusOfPayment:(NSTimer*)timer {
    
    PPOPayment *payment = timer.userInfo[@"PaymentKey"];
    
    if ([PPOPaymentTrackingManager isQueryingStatusOfPayment:payment]) {
        //return;
    }
    
    [PPOPaymentTrackingManager logIsQueryingStatusOfPayment:payment];
        
    [self queryPayment:payment
       withCredentials:self.credentials
    withOutcomeHandler:^(PPOOutcome *outcome, NSError *error) {
        
        NSLog(@"Query outcome handler fired");
        
        [PPOPaymentTrackingManager logIsNotQueryingStatusOfPayment:payment];
                
        NSLog(@"remaining session time %@", [PPOPaymentTrackingManager remainingSessionTimeoutForPayment:payment]);
        
        PPOErrorCode code = [PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue];
        
        if (outcome && code != PPOErrorPaymentProcessing) {
            [timer invalidate];
            void(^storedOutcomeManager)(PPOOutcome *, NSError *) = [PPOPaymentTrackingManager outcomeHandlerForPayment:payment];
            storedOutcomeManager(outcome, error);
            [PPOPaymentTrackingManager removePayment:payment];
        } else if (error && error.code == PPOErrorTransactionProcessingFailed) {
            [timer invalidate];
            void(^storedOutcomeManager)(PPOOutcome *, NSError *) = [PPOPaymentTrackingManager outcomeHandlerForPayment:payment];
            storedOutcomeManager(outcome, error);
            [PPOPaymentTrackingManager removePayment:payment];
        }
        
    }];
    
}

+(BOOL)noNetwork:(NSError*)error {
    return [[self noNetworkConnectionErrorCodes] containsObject:@(error.code)];
}

+(NSArray*)noNetworkConnectionErrorCodes {
    int codes[] = {
        kCFURLErrorTimedOut,
        kCFURLErrorCannotConnectToHost,
        kCFURLErrorNetworkConnectionLost,
        kCFURLErrorDNSLookupFailed,
        kCFURLErrorResourceUnavailable,
        kCFURLErrorNotConnectedToInternet,
        kCFURLErrorInternationalRoamingOff,
        kCFURLErrorCallIsActive,
        kCFURLErrorFileDoesNotExist,
        kCFURLErrorNoPermissionsToReadFile,
    };
    int size = sizeof(codes)/sizeof(int);
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i=0;i<size;++i){
        [array addObject:[NSNumber numberWithInt:codes[i]]];
    }
    return [array copy];
}

@end
