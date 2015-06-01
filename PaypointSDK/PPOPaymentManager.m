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
#import "PPOWebViewController.h"
#import "PPORedirect.h"
#import "PPOSDKConstants.h"
#import "PPODeviceInfo.h"
#import "PPOResourcesManager.h"
#import "PPOFinancialServices.h"
#import "PPOCustomer.h"
#import "PPOCustomField.h"
#import "PPOTimeManager.h"
#import "PPOPaymentTrackingManager.h"

@interface PPOPaymentManager () <NSURLSessionTaskDelegate, PPOWebViewControllerDelegate>
@property (nonatomic, strong) PPOPaymentEndpointManager *endpointManager;
@property (nonatomic, copy) void(^outcomeCompletion)(PPOOutcome *outcome, NSError *error);
@property (nonatomic, strong) PPOCredentials *credentials;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong, readwrite) NSOperationQueue *payments;
@property (nonatomic, strong) PPOWebViewController *webController;
@property (nonatomic, strong) PPODeviceInfo *deviceInfo;
@property (nonatomic, strong) PPOPaymentTrackingManager *trackingManager;
@end

@implementation PPOPaymentManager {
    BOOL _preventShowWebView;
    BOOL _isDismissingWebView;
}

-(instancetype)initWithBaseURL:(NSURL*)baseURL {
    self = [super init];
    if (self) {
        _endpointManager = [[PPOPaymentEndpointManager alloc] initWithBaseURL:baseURL];
    }
    return self;
}

-(PPOPaymentTrackingManager *)trackingManager {
    if (_trackingManager == nil) {
        _trackingManager = [PPOPaymentTrackingManager new];
    }
    return _trackingManager;
}

-(PPODeviceInfo *)deviceInfo {
    if (_deviceInfo == nil) {
        _deviceInfo = [PPODeviceInfo new];
    }
    return _deviceInfo;
}

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

-(void)makePayment:(PPOPayment*)payment withCredentials:(PPOCredentials*)credentials withTimeOut:(NSTimeInterval)timeout withCompletion:(void(^)(PPOOutcome *outcome, NSError *paymentFailure))completion {
    
    if ([self.trackingManager stateForPayment:payment] != PAYMENT_STATE_NON_EXISTENT) {
        completion(nil, [PPOErrorManager errorForCode:PPOErrorPaymentUnderway]);
        return;
    }
    
    NSError *invalid = [PPOPaymentValidator validateCredentials:credentials
                                                validateBaseURL:self.endpointManager.baseURL
                                                validatePayment:payment];
    
    if (invalid) {
        completion(nil, invalid);
        return;
    }
    
    [self.trackingManager appendPayment:payment
                            withTimeout:timeout
             commenceTimeoutImmediately:YES];
    
    NSURL *url = [self.endpointManager urlForSimplePayment:credentials.installationID];
    
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                            withURL:url
                                    withCredentials:credentials
                                        withPayment:payment
                                     withDeviceInfo:self.deviceInfo
                                        withTimeout:30.0f];

    self.outcomeCompletion = completion;
    self.credentials = credentials;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    __weak typeof(self) weakSelf = self;
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
        
        id json;
        NSError *invalidJSON;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        id redirectData = [weakSelf redirectData:json];
        
        if (invalidJSON) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                completion(nil, [PPOErrorManager errorForCode:PPOErrorServerFailure]);
            });
        } else if (redirectData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSNumber *timedOut = [self.trackingManager hasPaymentSessionTimedoutForPayment:payment];
                if (!timedOut || timedOut.boolValue == YES) {
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    completion(nil, [PPOErrorManager errorForCode:PPOErrorSessionTimedOut]);
                } else {
                    id redirectError = [self performSecureRedirect:redirectData forPayment:payment];
                    if (redirectError) {
                        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                        completion(nil, redirectError);
                    }
                }
            });
        } else if (json) {
            [weakSelf determineOutcome:json forPayment:payment completionHandler:completion];
        } else {
            //Perform get for transaction
        }
        
    }];
    
    [task resume];
    
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
    
    self.webController = [[PPOWebViewController alloc] initWithRedirect:redirect withDelegate:self];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    self.webController.view.frame = CGRectMake(-height, -width, width, height);
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.webController.view];
    
    return nil;
}

-(void)determineOutcome:(id)json forPayment:(PPOPayment*)payment completionHandler:(void(^)(PPOOutcome *outcome, NSError *paymentFailure))completion {
    NSError *error;
    PPOOutcome *outcome = [[PPOOutcome alloc] initWithData:json];
    if (outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == NO) {
        PPOErrorCode code = [PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue];
        error = [PPOErrorManager errorForCode:code];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.trackingManager removePayment:payment];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        completion(outcome, error);
    });
}

-(void)paymentStatus:(PPOPayment*)payment withCredentials:(PPOCredentials*)credentials withCompletion:(void(^)(PPOOutcome *outcome, NSError *networkError))completion {
    
    if (!payment) {
        completion(nil, nil);
        return;
    }
    
    NSURL *url = [self.endpointManager urlForPaymentWithID:payment.identifier
                                                  withInst:credentials.installationID];
    
    NSURLRequest *request = [self requestWithMethod:@"GET"
                                            withURL:url
                                    withCredentials:credentials
                                        withPayment:payment
                                     withDeviceInfo:self.deviceInfo
                                        withTimeout:5.0f];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    __weak typeof(self) weakSelf = self;
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
        
        id json;
        NSError *invalidJSON;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        if (invalidJSON) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                completion(nil, [PPOErrorManager errorForCode:PPOErrorServerFailure]);
            });
        } else if (json) {
            [weakSelf determineOutcome:json forPayment:payment completionHandler:completion];
        } else if (networkError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                if (((NSHTTPURLResponse*)response).statusCode == 404) {
                    completion(nil, [PPOErrorManager errorForCode:PPOErrorTransactionUnknown]);
                } else {
                    completion(nil, networkError);
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                completion(nil, [PPOErrorManager errorForCode:PPOErrorUnknown]);
            });
        }
        
    }];
    
    [task resume];
    
}

-(NSURLRequest*)requestWithMethod:(NSString*)method withURL:(NSURL*)url withCredentials:(PPOCredentials*)credentials withPayment:(PPOPayment*)payment withDeviceInfo:(PPODeviceInfo*)deviceInfo withTimeout:(CGFloat)timeout {
    NSData *data = [self buildPostBodyWithPayment:payment withDeviceInfo:deviceInfo];
    NSString *authorisation = [self authorisation:credentials];
    
    NSMutableURLRequest *request = [self mutableJSONRequestWithMethod:method withURL:url forPayment:payment withTimeout:timeout];
    [request setValue:authorisation forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:data];
    return [request copy];
}

-(NSMutableURLRequest*)mutableJSONRequestWithMethod:(NSString*)method withURL:(NSURL*)url forPayment:(PPOPayment*)payment withTimeout:(CGFloat)timeout {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeout];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"AP-Operation-ID" forHTTPHeaderField:payment.identifier];
    [request setHTTPMethod:method];
    return request;
}

-(NSString*)authorisation:(PPOCredentials*)credentials {
    return [NSString stringWithFormat:@"Bearer %@", credentials.token];
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

#pragma mark - PPOWebViewController

-(void)webViewController:(PPOWebViewController *)controller completedWithPaRes:(NSString *)paRes forTransactionWithID:(NSString *)transID {
    
    _preventShowWebView = YES;
    
    [self.trackingManager resumeTimeoutForPayment:controller.redirect.payment];
    
    if ([[UIApplication sharedApplication] keyWindow] == self.webController.view.superview) {
        [self.webController.view removeFromSuperview];
    }
    
    id data;
    if (paRes) {
        NSDictionary *dictionary = @{@"threeDSecureResponse": @{@"pares":paRes}};
        data = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    }
    
    NSURLSessionDataTask *task;
    NSURL *url = [self.endpointManager urlForResumePaymentWithInstallationID:INSTALLATION_ID transactionID:transID];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0f];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setValue:[self authorisation:self.credentials] forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:data];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSInteger statusCode = ((NSHTTPURLResponse*)response).statusCode;
        
        if (statusCode == 200) {
            
            NSError *invalidJSON;
            id json;
            if (data.length > 0) {
                json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
            }
            
            if (invalidJSON) {
                [self completePayment:controller.redirect.payment onMainThreadWithOutcome:nil withError:[PPOErrorManager errorForCode:PPOErrorServerFailure]];
                return;
            }
            
            PPOOutcome *outcome;
            if (json) {
                outcome = [[PPOOutcome alloc] initWithData:json];
            }
            
            if (outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == NO) {
                PPOErrorCode code = [PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue];
                [self completePayment:controller.redirect.payment onMainThreadWithOutcome:outcome withError:[PPOErrorManager errorForCode:code]];
            } else if (outcome.isSuccessful.boolValue == YES) {
                [self completePayment:controller.redirect.payment onMainThreadWithOutcome:outcome withError:nil];
            } else {
                [self completePayment:controller.redirect.payment onMainThreadWithOutcome:outcome withError:[PPOErrorManager errorForCode:PPOErrorUnknown]];
            }
            
        } else {
            [self completePayment:controller.redirect.payment onMainThreadWithOutcome:nil withError:[PPOErrorManager errorForCode:PPOErrorUnknown]];
        }
        
    }];
    
    [task resume];
    
}

-(void)webViewControllerDelayShowTimeoutExpired:(PPOWebViewController *)controller {
    if (!_preventShowWebView) {
        [self.trackingManager stopTimeoutForPayment:controller.redirect.payment];
        [self.webController.view removeFromSuperview];
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:self.webController];
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:navCon animated:YES completion:nil];
    }
}

-(void)webViewControllerSessionTimeoutExpired:(PPOWebViewController *)webController {
    [self handleError:[PPOErrorManager errorForCode:PPOErrorThreeDSecureTimedOut]
        webController:webController];
}

-(void)webViewController:(PPOWebViewController *)webController failedWithError:(NSError *)error {
    [self handleError:error
        webController:webController];
}

-(void)webViewControllerUserCancelled:(PPOWebViewController *)webController {
    [self handleError:[PPOErrorManager errorForCode:PPOErrorUserCancelled]
        webController:webController];
}

-(void)handleError:(NSError *)error webController:(PPOWebViewController *)webController {
    _preventShowWebView = YES;
    [self completePayment:webController.redirect.payment onMainThreadWithOutcome:nil withError:error];
}

-(void)completePayment:(PPOPayment*)payment onMainThreadWithOutcome:(PPOOutcome*)outcome withError:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.trackingManager removePayment:payment];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        //Depending on the delay show and session timeout timers, we may be currently showing the webview, or not.
        //Thus this check is essential.
        id controller = [[UIApplication sharedApplication] keyWindow].rootViewController.presentedViewController;
        if (controller && controller == self.webController.navigationController) {
            if (!_isDismissingWebView) {
                _isDismissingWebView = YES;
                [[[UIApplication sharedApplication] keyWindow].rootViewController dismissViewControllerAnimated:YES completion:^{
                    _isDismissingWebView = NO;
                    self.outcomeCompletion(outcome, error);
                    _preventShowWebView = NO;
                }];
            }
        } else {
            self.outcomeCompletion(outcome, error);
            _preventShowWebView = NO;
        }
    });
}

@end

@implementation PPOPaymentValidator

+(NSError*)validateCredentials:(PPOCredentials*)credentials validateBaseURL:(NSURL*)baseURL validatePayment:(PPOPayment*)payment {
    
    NSError *er;
    
    er = [self validateCredentials:credentials];
    
    if (er) {
        return er;
    }
    
    er = [self validatePayment:payment];
    
    if (er) {
        return er;
    }
    
    er = [self validateBaseURL:baseURL];
    
    if (er) {
        return er;
    }
    
    return nil;
}

+(NSError*)validatePayment:(PPOPayment*)payment {
    
    return [self validateTransaction:payment.transaction
                            withCard:payment.card];
    
}

+(NSError*)validateBaseURL:(NSURL*)baseURL {
    if (!baseURL) {
        return [PPOErrorManager errorForCode:PPOErrorSuppliedBaseURLInvalid];
    }
    return nil;
}

+(NSError*)validateCredentials:(PPOCredentials*)credentials {
    
    if (!credentials) {
        return [PPOErrorManager errorForCode:PPOErrorCredentialsNotFound];
    }
    
    if (!credentials.token || credentials.token.length == 0) {
        return [PPOErrorManager errorForCode:PPOErrorClientTokenInvalid];
    }
    
    if (!credentials.installationID || credentials.installationID.length == 0) {
        return [PPOErrorManager errorForCode:PPOErrorInstallationIDInvalid];
    }
    
    return nil;
}

+(NSError*)validateTransaction:(PPOTransaction*)transaction withCard:(PPOCreditCard*)card {
    
    NSString *strippedValue;
    
    strippedValue = [card.pan stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    BOOL containsLetters = [strippedValue rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location != NSNotFound;
    
    if (strippedValue.length < 13 || strippedValue.length > 19 || containsLetters) {
        return [PPOErrorManager errorForCode:PPOErrorCardPanInvalid];
    }
    
    if (![PPOLuhn validateString:strippedValue]) {
        return [PPOErrorManager errorForCode:PPOErrorLuhnCheckFailed];
    }
    
    strippedValue = [card.expiry stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length != 4) {
        return [PPOErrorManager errorForCode:PPOErrorCardExpiryDateInvalid];
    } else if ([PPOPaymentValidator cardExpiryHasExpired:strippedValue]) {
        return [PPOErrorManager errorForCode:PPOErrorCardExpiryDateExpired];
    }
    
    strippedValue = [card.cvv stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length < 3 || strippedValue.length > 4) {
        return [PPOErrorManager errorForCode:PPOErrorCVVInvalid];
    }
    
    strippedValue = [transaction.currency stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (strippedValue == nil || strippedValue.length == 0) {
        return [PPOErrorManager errorForCode:PPOErrorCurrencyInvalid];
    }
    
    if (transaction.amount == nil || transaction.amount.floatValue <= 0.0) {
        return [PPOErrorManager errorForCode:PPOErrorPaymentAmountInvalid];
    }
    
    return nil;
}

+(BOOL)cardExpiryHasExpired:(NSString*)expiry {
    return [PPOTimeManager cardExpiryDateExpired:expiry];
}

@end
