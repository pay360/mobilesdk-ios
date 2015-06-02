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
#import "PPOPaymentValidator.h"

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
    
    if ([self baseURLInvalid:self.endpointManager.baseURL]) return;
    if ([self credentialsInvalid:credentials]) return;
    if ([self paymentUnderway:payment]) return;
    
    if (![PPOPaymentTrackingManager allPaymentsComplete]) {
        outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorPaymentManagerOccupied]);
        return;
    }
    
    if ([self paymentInvalid:payment]) return;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self.endpointManager urlForSimplePayment:credentials.installationID]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0f];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:payment.identifier forHTTPHeaderField:@"AP-Operation-ID"];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", credentials.token] forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:[self buildPostBodyWithPayment:payment withDeviceInfo:self.deviceInfo]];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:[self transactionResponseHandlerForPayment:payment]];
    
    [task resume];
    
    __weak typeof(task) weakTask = task;
    [PPOPaymentTrackingManager appendPayment:payment
                                 withTimeout:timeout
                  commenceTimeoutImmediately:YES
                              timeoutHanlder:^{
                                  [weakTask cancel];
                              }];
    
}

-(void)paymentOutcome:(PPOPayment*)payment
      withCredentials:(PPOCredentials*)credentials
       withCompletion:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    
    self.credentials = credentials;
    self.outcomeHandler = outcomeHandler;
    
    if ([self baseURLInvalid:self.endpointManager.baseURL]) return;
    if ([self credentialsInvalid:credentials]) return;
    
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
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self.endpointManager urlForPaymentWithID:payment.identifier withInst:credentials.installationID]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:5.0f];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"AP-Operation-ID" forHTTPHeaderField:payment.identifier];
    [request setHTTPMethod:@"GET"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", credentials.token] forHTTPHeaderField:@"Authorization"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:[self transactionResponseHandlerForPayment:payment]];
    
    [task resume];
}

-(BOOL)baseURLInvalid:(NSURL*)url {
    NSError *invalid = [PPOPaymentValidator validateBaseURL:url];
    if (invalid) {
        self.outcomeHandler(nil, invalid);
        return YES;
    }
    return NO;
}

-(BOOL)credentialsInvalid:(PPOCredentials*)credentials {
    
    NSError *invalid = [PPOPaymentValidator validateCredentials:credentials];
    if (invalid) {
        self.outcomeHandler(nil, invalid);
        return YES;
    }
    return NO;
}

-(BOOL)paymentInvalid:(PPOPayment*)payment {
    
    NSError *invalid = [PPOPaymentValidator validatePayment:payment];
    if (invalid) {
        self.outcomeHandler(nil, invalid);
        return YES;
    }
    return NO;
}

-(BOOL)paymentUnderway:(PPOPayment*)payment {
    
    PAYMENT_STATE state = [PPOPaymentTrackingManager stateForPayment:payment];
    
    if (state != PAYMENT_STATE_NON_EXISTENT) {
        self.outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorPaymentProcessing]);
        return YES;
    }
    
    return NO;
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

-(NSData*)buildPostBodyWithPayment:(PPOPayment*)payment withDeviceInfo:(PPODeviceInfo*)deviceInfo {
    
    id value = [deviceInfo jsonObjectRepresentation];
    id i = (value) ?: [NSNull null];
    value = [payment.transaction jsonObjectRepresentation];
    id t = (value) ?: [NSNull null];
    value = [payment.card jsonObjectRepresentation];
    id c = (value) ?: [NSNull null];
    value = [payment.address jsonObjectRepresentation];
    id a = (value) ?: [NSNull null];
    NSDictionary *merchantAppPlist = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]];
    value = [merchantAppPlist objectForKey:@"CFBundleName"];
    id apn = ([value isKindOfClass:[NSString class]]) ? value : [NSNull null];
    value = [merchantAppPlist objectForKey:@"CFBundleShortVersionString"];
    id apv = ([value isKindOfClass:[NSString class]]) ? value : [NSNull null];
    value = [NSString stringWithFormat:@"pp_ios_sdk:%@", [[PPOResourcesManager infoPlist] objectForKey:@"CFBundleShortVersionString"]];
    id sdkv = ([value isKindOfClass:[NSString class]]) ? value : [NSNull class];
    
    id object = @{
                  @"merchantAppName"    : apn,
                  @"merchantAppVersion" : apv,
                  @"sdkVersion"         : sdkv,
                  @"deviceInfo"         : i,
                  @"transaction"        : t,
                  @"paymentMethod"      : @{
                                            @"card"             : c,
                                            @"billingAddress"   : a
                                            }
                  };
    
    NSMutableDictionary *mutableObject;
    
    if (payment.financialServices || payment.customer || payment.customFields.count) {
        mutableObject = [object mutableCopy];
    }
    
    if (payment.financialServices) {
        value = [payment.financialServices jsonObjectRepresentation];
        id f = (value) ?: [NSNull null];
        [mutableObject setValue:f forKey:@"financialServices"];
    }
    
    if (payment.customer) {
        value = [payment.customer jsonObjectRepresentation];
        id cus = (value) ?: [NSNull null];
        [mutableObject setValue:cus forKey:@"customer"];
    }
    
    if (payment.customFields.count) {
        NSMutableArray *collector = [NSMutableArray new];
        id field;
        for (PPOCustomField *f in payment.customFields) {
            value = [f jsonObjectRepresentation];
            field = (value) ?: [NSNull null];
            [collector addObject:field];
        }
        if (collector.count) {
            [mutableObject setValue:@{PAYMENT_RESPONSE_CUSTOM_FIELDS_STATE : [collector copy]}
                             forKey:PAYMENT_RESPONSE_CUSTOM_FIELDS];
        }
    }
    
    if (mutableObject) {
        object = [mutableObject copy];
    }
    
    return [NSJSONSerialization dataWithJSONObject:object
                                           options:NSJSONWritingPrettyPrinted
                                             error:nil];
}

@end
