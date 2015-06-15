//
//  PPOURLRequestManager.m
//  Paypoint
//
//  Created by Robert Nash on 03/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOURLRequestManager.h"
#import "PPOPayment.h"
#import "PPOTransaction.h"
//#import "PPOCredentials.h"
#import "PPOCreditCard.h"
#import "PPODeviceInfo.h"
#import "PPOPayment.h"
#import "PPOResourcesManager.h"
#import "PPOBillingAddress.h"
#import "PPOFinancialService.h"
#import "PPOCustomer.h"
#import "PPOCustomField.h"
#import "PPOSDKConstants.h"

@implementation PPOURLRequestManager

+(NSURLRequest*)requestWithURL:(NSURL*)url withMethod:(NSString*)method withTimeout:(CGFloat)timeout withToken:(NSString*)token withBody:(NSData*)body forPaymentWithID:(NSString*)paymentID {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeout];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:method];
    if (paymentID) [request setValue:paymentID forHTTPHeaderField:@"AP-Operation-ID"];
    if (body) [request setHTTPBody:body];;
    return [request copy];
}

+(NSData*)buildPostBodyWithPayment:(PPOPayment*)payment withDeviceInfo:(PPODeviceInfo*)deviceInfo {
    
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
