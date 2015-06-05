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
    
    id completion = [self transactionResponseHandlerForPayment:payment withOutcomeHandler:outcomeHandler];
    
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
            outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorPaymentProcessing]);
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
    
    NSURL *url = [self.endpointManager urlForPaymentWithID:payment.identifier
                                                  withInst:credentials.installationID];
    
    //The payment identifier is passed in the url.
    NSURLRequest *request = [PPOURLRequestManager requestWithURL:url
                                                      withMethod:@"GET"
                                                     withTimeout:5.0f
                                                       withToken:credentials.token
                                                        withBody:nil
                                                forPaymentWithID:nil];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    id completion = [self transactionResponseHandlerForQuery:payment withOutcomeHandler:outcomeHandler];
    
    NSURLSessionDataTask *task = [self.querySession dataTaskWithRequest:request
                                                      completionHandler:completion];
    
    [task resume];

}

-(void(^)(NSData *, NSURLResponse *, NSError *))transactionResponseHandlerForQuery:(PPOPayment*)payment withOutcomeHandler:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            outcomeHandler(outcome, networkError);
        });

    };
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (invalidJSON) {
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [PPOPaymentTrackingManager removePayment:payment];
                outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorServerFailure]);
                
            } else if (redirectData) {
                
                PPORedirect *redirect = [[PPORedirect alloc] initWithData:redirectData];
                redirect.transactionID = [redirectData objectForKey:@"transactionId"];
                redirect.payment = payment;
                
                if (redirect.request) {
                    
                    self.webFormManager = [[PPOWebFormManager alloc] initWithRedirect:redirect
                                                                      withCredentials:self.credentials
                                                                          withSession:self.paymentSession
                                                                  withEndpointManager:self.endpointManager
                                                                          withOutcome:^(PPOOutcome *outcome, NSError *error) {
                                                                              
                                                                              [weakSelf handlePayment:payment
                                                                                          withOutcome:outcome
                                                                                     withNetworkError:error
                                                                                   withOutcomeHandler:outcomeHandler];
                                                                              
                                                                          }];
                    
                } else {
                    
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    [PPOPaymentTrackingManager removePayment:payment];
                    outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorProcessingThreeDSecure]);
                    
                }
                
            } else if (json) {
                
                [weakSelf handlePayment:payment
                            withOutcome:[[PPOOutcome alloc] initWithData:json]
                       withNetworkError:networkError
                     withOutcomeHandler:outcomeHandler];
                
            } else if (networkError) {
                
                [weakSelf handlePayment:payment
                            withOutcome:nil
                       withNetworkError:networkError
                     withOutcomeHandler:outcomeHandler];
                
            } else {
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [PPOPaymentTrackingManager removePayment:payment];
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

-(void)handlePayment:(PPOPayment*)payment
         withOutcome:(PPOOutcome*)outcome
    withNetworkError:(NSError*)networkError
  withOutcomeHandler:(void(^)(PPOOutcome *outcome, NSError*))outcomeHandler {
    
    __block NSError *e;
    
    if (outcome && outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == NO) {
        e = [PPOErrorManager errorForCode:[PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue]];
    }
    
    if (e.code == PPOErrorPaymentProcessing || (networkError && networkError.code != NSURLErrorCancelled)) {
        
        [self queryPayment:payment withCredentials:self.credentials withOutcomeHandler:^(PPOOutcome *queryOutcome, NSError *error) {
            
            [self handlePayment:payment
                    withOutcome:queryOutcome
               withNetworkError:error
             withOutcomeHandler:outcomeHandler];
            
        }];
        
    } else {
        
        if (networkError.code == NSURLErrorCancelled) {
            e = [PPOErrorManager errorForCode:PPOErrorSessionTimedOut];
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [PPOPaymentTrackingManager removePayment:payment];
        outcomeHandler(outcome, e);
        
    }
    
}

@end
