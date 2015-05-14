//
//  PPORedirect.m
//  Paypoint
//
//  Created by Robert Nash on 14/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPORedirect.h"

@implementation PPORedirect

-(instancetype)initWithData:(NSDictionary *)data {
    self = [super init];
    if (self) {
        NSString *acsURLString = [data objectForKey:@"acsUrl"];
        if ([acsURLString isKindOfClass:[NSString class]]) {
            NSString *md = [data objectForKey:@"md"];
            NSString *pareq = [data objectForKey:@"pareq"];
            NSNumber *sessionTimeout = [data objectForKey:@"sessionTimeout"];
            NSTimeInterval secondsTimeout = sessionTimeout.doubleValue/1000;
            NSNumber *acsTimeout = [data objectForKey:@"redirectTimeout"];
            NSTimeInterval secondsDelayShow = (acsTimeout) ? acsTimeout.doubleValue/1000 : 5;
            NSString *termUrlString = [data objectForKey:@"termUrl"];
            NSURL *termURL = [NSURL URLWithString:termUrlString];
            self.termURL = termURL;
            NSURL *acsURL = [NSURL URLWithString:acsURLString];
            if (acsURL) {
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:acsURL];
                [request setHTTPMethod:@"POST"];
                
                NSString *string = [NSString stringWithFormat:@"PaReq=%@&MD=%@&TermUrl=%@", [self urlencode:pareq], [self urlencode:md], termURL];
                NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
                
                [request setHTTPBody:data];
                
                self.request = [request copy];
            }
            
            if ([sessionTimeout isKindOfClass:[NSNumber class]]) {
                self.sessionTimeoutTimeInterval = @(secondsTimeout);
            }
            
            if ([acsTimeout isKindOfClass:[NSNumber class]]) {
                self.delayTimeInterval = @(secondsDelayShow);
            }
        }
    }
    return self;
}

-(NSString *)urlencode:(NSString*)string {
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

@end
