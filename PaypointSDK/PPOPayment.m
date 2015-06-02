//
//  PPOPayment.m
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPayment.h"

@interface PPOPayment ()
@property (nonatomic, readwrite, copy) NSString *identifier;
@end

@implementation PPOPayment

-(NSString *)identifier {
    if (_identifier == nil) {
        _identifier = [NSUUID UUID].UUIDString;
    }
    return _identifier;
}

-(BOOL)isEqual:(id)object {
    
    if (self == object) {
        return YES;
    }
    
    return [self isEqualToPayment:object];
}

-(BOOL)isEqualToPayment:(PPOPayment*)payment {
    return (payment && [payment isKindOfClass:[PPOPayment class]] && [self.identifier isEqualToString:payment.identifier]);
}

-(NSUInteger)hash {
    return [self.identifier hash];
}

@end
