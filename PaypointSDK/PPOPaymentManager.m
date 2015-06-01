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

@interface PPOPaymentManager () <NSURLSessionTaskDelegate>
@property (nonatomic, strong) PPOPaymentEndpointManager *endpointManager;
@property (nonatomic, copy) void(^outcomeHandler)(PPOOutcome *outcome, NSError *error);
@property (nonatomic, strong) PPOCredentials *credentials;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) PPOWebViewController *webController;
@property (nonatomic, strong) PPODeviceInfo *deviceInfo;
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
    withCompletion:(void(^)(PPOOutcome *outcome, NSError *paymentFailure))outcomeHandler {
    
    self.credentials = credentials;
    self.outcomeHandler = outcomeHandler;
    
    if ([self baseURLInvalid:self.endpointManager.baseURL]) return;
    if ([self credentialsInvalid:credentials]) return;
    if ([self paymentInvalid:payment]) return;
    if ([self paymentUnderway:payment]) return;
    
    [PPOPaymentTrackingManager appendPayment:payment
                                 withTimeout:timeout
                  commenceTimeoutImmediately:YES];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self.endpointManager urlForSimplePayment:credentials.installationID]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0f];
    
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:@"AP-Operation-ID" forHTTPHeaderField:payment.identifier];
    
    [request setHTTPMethod:@"POST"];
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@", credentials.token] forHTTPHeaderField:@"Authorization"];
    
    [request setHTTPBody:[self buildPostBodyWithPayment:payment withDeviceInfo:self.deviceInfo]];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    id completionHandler = [self transactionResponseHandlerForPayment:payment
                                                      attemptRecovery:NO];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:completionHandler];
    
    [task resume];
    
}

-(void)paymentStatus:(PPOPayment*)payment
     withCredentials:(PPOCredentials*)credentials
      withCompletion:(void(^)(PPOOutcome *outcome, NSError *networkError))outcomeHandler {
    
    self.credentials = credentials;
    self.outcomeHandler = outcomeHandler;
    
    if ([self baseURLInvalid:self.endpointManager.baseURL]) return;
    if ([self credentialsInvalid:credentials]) return;
    if ([self paymentInvalid:payment]) return;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self.endpointManager urlForPaymentWithID:payment.identifier withInst:credentials.installationID]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:5.0f];
    
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:@"AP-Operation-ID" forHTTPHeaderField:payment.identifier];
    
    [request setHTTPMethod:@"GET"];
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@", credentials.token] forHTTPHeaderField:@"Authorization"];
    
    [request setHTTPBody:[self buildPostBodyWithPayment:payment withDeviceInfo:self.deviceInfo]];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    id completionHandler = [self transactionResponseHandlerForPayment:payment
                                                      attemptRecovery:NO];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:completionHandler];
    
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
        self.outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorPaymentUnderway]);
        return YES;
    }
    
    return NO;
}

-(void(^)(NSData *data, NSURLResponse *response, NSError *networkError))transactionResponseHandlerForPayment:(PPOPayment*)payment attemptRecovery:(BOOL)retry {
    
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
                weakSelf.outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorServerFailure]);
            });
        } else if (redirectData) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSNumber *timedOut = [PPOPaymentTrackingManager hasPaymentSessionTimedoutForPayment:payment];
                if (!timedOut || timedOut.boolValue == YES) {
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    weakSelf.outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorSessionTimedOut]);
                } else {
                    NSError *redirectError = [weakSelf performSecureRedirect:redirectData forPayment:payment];
                    if (redirectError) {
                        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                        weakSelf.outcomeHandler(nil, redirectError);
                    }
                }
                
            });
            
        } else if (json) {
            [weakSelf determineOutcome:json forPayment:payment];
        } else if (retry) {
            
            //Perform get for transaction
            
        } else if (networkError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                if (((NSHTTPURLResponse*)response).statusCode == 404) {
                    weakSelf.outcomeHandler(nil, [PPOErrorManager errorForCode:PPOErrorPaymentUnknown]);
                } else {
                    weakSelf.outcomeHandler(nil, networkError);
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
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
    
    self.webController = [[PPOWebViewController alloc] initWithRedirect:redirect withDelegate:self];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    self.webController.view.frame = CGRectMake(-height, -width, width, height);
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.webController.view];
    
    return nil;
}

-(void)determineOutcome:(id)json forPayment:(PPOPayment*)payment {
    
    NSError *error;
    
    PPOOutcome *outcome = [[PPOOutcome alloc] initWithData:json];
    if (outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == NO) {
        PPOErrorCode code = [PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue];
        error = [PPOErrorManager errorForCode:code];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [PPOPaymentTrackingManager removePayment:payment];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.outcomeHandler(outcome, error);
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

@implementation PPOPaymentValidator

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
