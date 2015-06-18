//
//  PPOCard.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOCard.h"

@implementation PPOCard

-(NSDictionary*)jsonObjectRepresentation {
    id pan = ([self cleanString:self.pan]) ?: [NSNull null];
    id cvv = ([self cleanString:self.cvv]) ?: [NSNull null];
    id expiry = (self.expiry) ? [self cleanString:self.expiry] : [NSNull null];
    id cardholder = (self.cardHolderName) ?: [NSNull null];
    
    return @{
             @"pan": pan,
             @"cv2": cvv,
             @"expiryDate": expiry,
             @"cardHolderName": cardholder
             };
}

-(NSString*)cleanString:(NSString*)string {
    return [string stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
