//
//  PPOCreditCard.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOCreditCard.h"

@interface PPOCreditCard ()
@property (nonatomic, strong, readwrite) NSString *pan;
@property (nonatomic, strong, readwrite) NSString *cvv;
@property (nonatomic, strong, readwrite) NSString *expiry;
@property (nonatomic, strong, readwrite) NSString *cardHolderName;
@end

@implementation PPOCreditCard

-(instancetype)initWithPan:(NSString*)pan withCode:(NSString*)cvv withExpiry:(NSString*)expiry withName:(NSString*)cardholder {
    self = [super init];
    if (self) {
        _pan = pan;
        _cvv = cvv;
        _expiry = expiry;
        _cardHolderName = cardholder;
    }
    return self;
}

-(NSDictionary*)jsonObjectRepresentation {
    id pan = (self.pan) ?: [NSNull null];
    id cvv = (self.cvv) ?: [NSNull null];
    id expiry = (self.expiry) ? [self cleanExpiry:self.expiry] : [NSNull null];
    id cardholder = (self.cardHolderName) ?: [NSNull null];
    
    return @{
             @"pan": pan,
             @"cv2": cvv,
             @"expiryDate": expiry,
             @"cardHolderName": cardholder
             };
}

-(NSString*)cleanExpiry:(NSString*)expiry {
    return [expiry stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
