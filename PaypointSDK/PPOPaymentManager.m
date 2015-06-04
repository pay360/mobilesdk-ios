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
@property (nonatomic, strong) void(^outcomeHandler)(PPOOutcome *outcome, NSError *error);
@property (nonatomic, strong) PPOCredentials *credentials;
@property (nonatomic, strong) NSURLSession *session;
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
        NSOperationQueue *q = [NSOperationQueue new];
        q.name = @"Payments_Queue";
        q.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:q];
    }
    return self;
}

-(void)makePayment:(PPOPayment*)payment
   withCredentials:(PPOCredentials*)credentials
       withTimeOut:(NSTimeInterval)timeout
    withCompletion:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    
    self.credentials = credentials;
    self.outcomeHandler = outcomeHandler;
    
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
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:[self transactionResponseHandlerForPayment:payment withOutcomeHandler:outcomeHandler]];
    
    [task resume];
    
    __weak typeof(task) weakTask = task;
    __weak typeof(self) weakSelf = self;
    [PPOPaymentTrackingManager appendPayment:payment
                                 withTimeout:timeout
                  commenceTimeoutImmediately:YES
                              timeoutHandler:^{
                                  [weakTask cancel];
                                  [weakSelf.pollingTimer invalidate];
                              }];
    
}

-(void)paymentOutcome:(PPOPayment*)payment
      withCredentials:(PPOCredentials*)credentials
       withCompletion:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    
    self.credentials = credentials;
    self.outcomeHandler = outcomeHandler;
    
    if ([PPOValidator baseURLInvalid:self.endpointManager.baseURL withHandler:outcomeHandler]) return;
    if ([PPOValidator credentialsInvalid:credentials withHandler:outcomeHandler]) return;
    
    PAYMENT_STATE state = [PPOPaymentTrackingManager stateForPayment:payment];
    
    switch (state) {
        case PAYMENT_STATE_NON_EXISTENT: {
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
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:[self transactionResponseHandlerForPayment:payment withOutcomeHandler:outcomeHandler]];
    
    [task resume];
    
    __weak typeof(self) weakSelf = self;
    [PPOPaymentTrackingManager setTimeoutHandler:^{
        [weakSelf.pollingTimer invalidate];
        if (weakSelf.session.delegateQueue.operationCount > 0) {
            [weakSelf.session invalidateAndCancel];
        } else {
            weakSelf.outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorSessionTimedOut]);
        }
    } forPayment:payment];
    
}

-(void(^)(NSData *, NSURLResponse *, NSError *))transactionResponseHandlerForPayment:(PPOPayment*)payment
                                                                  withOutcomeHandler:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    
    __weak typeof(self) weakSelf = self;
    
    return ^ (NSData *data, NSURLResponse *response, NSError *networkError) {
        
        id json;
        
        NSError *invalidJSON;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        id redirectData = [weakSelf redirectData:json];
        
        if (invalidJSON) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [PPOPaymentTrackingManager removePayment:payment];
                weakSelf.outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorServerFailure]);
            });
        } else if (redirectData) {

            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSError *redirectError = [weakSelf performSecureRedirect:redirectData forPayment:payment];
                if (redirectError) {
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    [PPOPaymentTrackingManager removePayment:payment];
                    weakSelf.outcomeHandler(nil, redirectError);
                }
                
            });
            
        } else if (json) {
            [weakSelf determineOutcome:json
                            forPayment:payment
                       forNetworkError:networkError];
        } else if (networkError) {
            if ([PPOPaymentManager noNetwork:networkError]) {
                [weakSelf pollStatusOfPayment:payment];
            } else if ([networkError.domain isEqualToString:NSURLErrorDomain] && networkError.code == NSURLErrorCancelled) {
                weakSelf.outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorSessionTimedOut]);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    [PPOPaymentTrackingManager removePayment:payment];
                    weakSelf.outcomeHandler(nil, networkError);
                });
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [PPOPaymentTrackingManager removePayment:payment];
                weakSelf.outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorUnknown]);
            });
        }
        
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

-(NSError*)performSecureRedirect:(NSDictionary*)data forPayment:(PPOPayment*)payment {
    
    PPORedirect *redirect = [[PPORedirect alloc] initWithData:data];
    redirect.transactionID = [data objectForKey:@"transactionId"];
    redirect.payment = payment;
    if (!redirect.request) {
        return [PPOErrorManager errorForCode:PPOErrorProcessingThreeDSecure];
    }
    
    self.webFormManager = [[PPOWebFormManager alloc] initWithRedirect:redirect
                                                      withCredentials:self.credentials
                                                          withSession:self.session
                                                  withEndpointManager:self.endpointManager
                                                          withOutcome:self.outcomeHandler];
    
    return nil;
}

-(void)determineOutcome:(id)json forPayment:(PPOPayment*)payment forNetworkError:(NSError*)error {
    
    NSError *e;
    
    PPOOutcome *outcome = [[PPOOutcome alloc] initWithData:json];
    
    if (outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == NO) {
        PPOErrorCode code = [PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue];
        e = [PPOErrorManager errorForCode:code];
    }
    
    if (!e) {
        e = error;
    }
    
    if (self.pollingTimer && outcome.reasonCode.integerValue != PPOErrorPaymentProcessing) {
        if ([self.pollingTimer isValid]) {
            [self.pollingTimer invalidate];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [PPOPaymentTrackingManager removePayment:payment];
            self.outcomeHandler(outcome, e);
        });
    } else if ([PPOPaymentManager noNetwork:e]) {
        if (![self.pollingTimer isValid]) {
            [self pollStatusOfPayment:payment];
        }
    } else if (![self.pollingTimer isValid]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [PPOPaymentTrackingManager removePayment:payment];
            self.outcomeHandler(outcome, e);
        });
    }
    
}

-(void)pollStatusOfPayment:(PPOPayment*)payment {
    
    if (!payment) return;
    
    NSNumber *sessionTimeoutInterval = [PPOPaymentTrackingManager remainingSessionTimeoutForPayment:payment];
    
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

-(void)statusOfPayment:(NSTimer*)timer {
    
    PPOPayment *payment = timer.userInfo[@"PaymentKey"];
        
    __weak typeof(self) weakSelf = self;
    [self queryPayment:payment
       withCredentials:self.credentials
    withOutcomeHandler:^(PPOOutcome *outcome, NSError *error) {
        
        if (outcome && outcome.reasonCode.integerValue != PPOErrorPaymentProcessing) {
            [timer invalidate];
            weakSelf.outcomeHandler(outcome, error);
        }
        
    }];;
    
}

@end
