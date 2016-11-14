//
//  PPOPayment.m
//  Pay360
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import "PPOPayment.h"
#import "PPOPaymentReference.h"
#import <objc/runtime.h>

NSString *kPaymentIdentifierKey = @"keyPaymentIdentifier";

@implementation PPOPayment

-(BOOL)isEqual:(id)object {
    PPOPayment *payment;
    if ([object isKindOfClass:[PPOPayment class]]) {
        payment = object;
    }
    
    PPOPaymentReference *referenceA = objc_getAssociatedObject(self, &kPaymentIdentifierKey);
    PPOPaymentReference *referenceB = objc_getAssociatedObject(payment, &kPaymentIdentifierKey);
    
    return (payment && [referenceA.identifier isEqualToString:referenceB.identifier]);
}

-(NSUInteger)hash {
    
    PPOPaymentReference *reference = objc_getAssociatedObject(self, &kPaymentIdentifierKey);
    
    return [reference.identifier hash];
}

@end
