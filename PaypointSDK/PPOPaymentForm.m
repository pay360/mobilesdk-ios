//
//  PPOPaymentForm.m
//  Paypoint
//
//  Created by Robert Nash on 23/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentForm.h"
#import "PPOLuhn.h"

@implementation PPOPaymentForm

-(BOOL)isComplete {
    if (self.cardNumber == nil || self.cardNumber.length == 0 || ![PPOLuhn validateString:self.cardNumber]) {
        return NO;
    }
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
    return YES;
}

-(void)setExpiry:(NSString *)expiry {
    _expiry = [expiry stringByReplacingOccurrencesOfString:@" " withString:@""];
}
@end
