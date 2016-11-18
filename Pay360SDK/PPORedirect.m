//
//  PPORedirect.m
//  Pay360
//
//  Created by Robert Nash on 14/05/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import "PPORedirect.h"
#import "PPOSDKConstants.h"
#import <objc/runtime.h>

@implementation PPORedirect

-(instancetype)initWithData:(NSDictionary *)data forPayment:(PPOPayment*)payment {
    
    self = [super init];
    if (self) {
        
        if (!data || ![data isKindOfClass:[NSDictionary class]]) {
            return self;
        }
        
        _payment = payment;
        
        id value = [data objectForKey:TRANSACTION_RESPONSE_TRANSACTION_KEY];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            id transactionID = [value objectForKey:TRANSACTION_RESPONSE_TRANSACTION_ID_KEY];
            if ([transactionID isKindOfClass:[NSString class]]) {
                _transactionID = transactionID;
            }
        }
        
        data = [data objectForKey:THREE_D_SECURE_KEY];
        
        value = [data objectForKey:THREE_D_SECURE_TERMINATION_URL_KEY];
        
        if (!value || [value isKindOfClass:[NSNull class]]) {
            return self;
        }
        
        _termURL = [self parseURL:value];
        
        value = [data objectForKey:THREE_D_SECURE_PAREQ_KEY];
        
        if (!value || [value isKindOfClass:[NSNull class]]) {
            return self;
        }
        
        value = [data objectForKey:THREE_D_SECURE_MD_KEY];
        
        if (!value || [value isKindOfClass:[NSNull class]]) {
            return self;
        }
        
        NSString *body = [NSString stringWithFormat:@"PaReq=%@&MD=%@&TermUrl=%@",
                          [self urlencode:[self parseStringParam:[data objectForKey:THREE_D_SECURE_PAREQ_KEY]]],
                          [self urlencode:[self parseStringParam:[data objectForKey:THREE_D_SECURE_MD_KEY]]],
                           self.termURL
                          ];
        
        value = [data objectForKey:THREE_D_SECURE_ACS_URL_KEY];
        
        if (!value || [value isKindOfClass:[NSNull class]]) {
            return self;
        }
        
        NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self parseURL:value]];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:bodyData];
        _request = [request copy];
        
        _sessionTimeoutTimeInterval = [self parseSessionTimeout:[data objectForKey:THREE_D_SECURE_SESSION_TIMEOUT_TIME_KEY]];
        
        _delayTimeInterval = [self parseDelayShowTimeout:[data objectForKey:THREE_D_SECURE_DELAYSHOW_TIME_KEY]];
    }
    return self;
}

-(NSURL*)parseURL:(NSString*)value {
    if ([self parseStringParam:value] != nil) {
        return [NSURL URLWithString:value];
    }
    return nil;
}

-(NSString*)parseStringParam:(NSString*)param {
    if (param && [param isKindOfClass:[NSString class]] && param.length > 0) {
        return param;
    }
    return nil;
}

-(NSString *)urlencode:(NSString*)string {
    if ([self parseStringParam:string] == nil) {
        return nil;
    }
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[string UTF8String];
    unsigned long sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

-(NSNumber*)parseSessionTimeout:(NSNumber*)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        return @(value.doubleValue/1000);
    }
    return nil;
}

-(NSNumber*)parseDelayShowTimeout:(NSNumber*)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        return @((value) ? value.doubleValue/1000 : 5);
    }
    return nil;
}

+(BOOL)requiresRedirect:(id)json {
    
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    id value = [json objectForKey:THREE_D_SECURE_KEY];
    return (value && [value isKindOfClass:[NSDictionary class]]);
    
}

@end
