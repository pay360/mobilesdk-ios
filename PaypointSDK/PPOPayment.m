//
//  PPOPayment.m
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPayment.h"

@implementation PPOPayment

-(BOOL)isEqual:(id)object {
    PPOPayment *payment;
    if ([object isKindOfClass:[PPOPayment class]]) {
        payment = object;
    }
    return (payment && [self.identifier isEqualToString:payment.identifier]);
}

-(NSUInteger)hash {
    return [self.identifier hash];
}

@end
