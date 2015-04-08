//
//  FormDetails.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "FormDetails.h"
#import <PaypointSDK/PPOLuhn.h>

@implementation FormDetails

-(BOOL)isComplete {
    if (self.cardNumber.length < 16 || self.cardNumber.length > 19) {
        return NO;
    }
    if (self.expiry == nil) {
        return NO;
    }
    if (self.cvv == nil || self.cvv.length == 0) {
        return NO;
    }
    if (self.cvv.length < 3 || self.cvv.length > 4) {
        return NO;
    }
    return [PPOLuhn validateString:self.cardNumber];
}

-(void)setExpiry:(NSString *)expiry {
    _expiry = [expiry stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
