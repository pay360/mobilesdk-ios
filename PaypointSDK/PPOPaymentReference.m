//
//  PPOPaymentReference.m
//  PayPointPayments
//
//  Created by Robert Nash on 09/07/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentReference.h"

@implementation PPOPaymentReference

-(instancetype)initWithIdentifier:(NSString *)identifer {
    self = [super init];
    if (self) {
        _identifier = identifer;
    }
    return self;
}

@end
