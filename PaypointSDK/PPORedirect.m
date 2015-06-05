//
//  PPORedirect.m
//  Paypoint
//
//  Created by Robert Nash on 14/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPORedirect.h"
#import "PPOSDKConstants.h"

@implementation PPORedirect

-(instancetype)initWithData:(NSDictionary *)data {
    self = [super init];
    if (self) {
        
        if (!data) {
            return self;
        }
        
        id value;
        
        value = [data objectForKey:THREE_D_SECURE_TERMINATION_URL_KEY];
        
        if (!value || [value isKindOfClass:[NSNull class]]) {
            return self;
        }
        
        self.termURL = [self parseURL:value];
        
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
        self.request = [request copy];
        
        self.sessionTimeoutTimeInterval = [self parseSessionTimeout:[data objectForKey:THREE_D_SECURE_SESSION_TIMEOUT_TIME_KEY]];
        
        self.delayTimeInterval = [self parseDelayShowTimeout:[data objectForKey:THREE_D_SECURE_DELAYSHOW_TIME_KEY]];
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

@end
