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
                                                 completionHandler:[self transactionResponseHandlerForPayment:payment]];
    
    [task resume];
    
    __weak typeof(task) weakTask = task;
    [PPOPaymentTrackingManager appendPayment:payment
                                 withTimeout:timeout
                  commenceTimeoutImmediately:YES
                              timeoutHandler:^{
                                  [weakTask cancel];
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
            [self queryPayment:payment withCredentials:credentials];
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

-(void)queryPayment:(PPOPayment*)payment withCredentials:(PPOCredentials*)credentials {
    
    NSURL *url = [self.endpointManager urlForPaymentWithID:payment.identifier
                                                  withInst:credentials.installationID];
    
    NSURLRequest *request = [PPOURLRequestManager requestWithURL:url
                                                      withMethod:@"GET"
                                                     withTimeout:5.0f
                                                       withToken:credentials.token
                                                        withBody:nil
                                                forPaymentWithID:payment.identifier];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:[self transactionResponseHandlerForPayment:payment]];
    
    [task resume];
}

-(void(^)(NSData *, NSURLResponse *, NSError *))transactionResponseHandlerForPayment:(PPOPayment*)payment {
    
    __weak typeof(self) weakSelf = self;
    
#warning clean up logs
    
    return ^ (NSData *data, NSURLResponse *response, NSError *networkError) {
        
        id json;
        
        NSError *invalidJSON;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        id redirectData = [weakSelf redirectData:json];
        
        NSLog(@"1");
        
        if (invalidJSON) {
            NSLog(@"2");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [PPOPaymentTrackingManager removePayment:payment];
                weakSelf.outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorServerFailure]);
            });
        } else if (redirectData) {

            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSLog(@"5");
                NSError *redirectError = [weakSelf performSecureRedirect:redirectData forPayment:payment];
                if (redirectError) {
                    NSLog(@"6");
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    [PPOPaymentTrackingManager removePayment:payment];
                    weakSelf.outcomeHandler(nil, redirectError);
                }
                
            });
            
        } else if (json) {
            NSLog(@"7");
            [weakSelf determineOutcome:json forPayment:payment forNetworkError:networkError];
        } else if (networkError) {
            NSLog(@"9");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [PPOPaymentTrackingManager removePayment:payment];
                weakSelf.outcomeHandler(nil, networkError);
            });
        } else {
            NSLog(@"13");
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [PPOPaymentTrackingManager removePayment:payment];
        self.outcomeHandler(outcome, e);
    });
    
}

@end
