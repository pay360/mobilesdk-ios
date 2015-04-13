//
//  FormDetails.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "FormDetails.h"
#import <PaypointSDK/PPOLuhn.h>
#import "NSString+strip.h"

@implementation FormDetails

-(BOOL)isComplete {
    
    NSString *entry;
    
    entry = [self.expiry stripWhitespace];
    
    if (entry == nil || entry.length == 0) {
        return NO;
    }
    
    entry = [self.cvv stripWhitespace];
    
    if (entry == nil || entry.length < 3 || entry.length > 4) {
        return NO;
    }
    
    entry = [self.cardNumber stripWhitespace];
    
    if (entry.length < 15 || entry.length > 19) {
        return NO;
    }
    
//    entry = [self.currency stripWhitespace];
//    
//    if (entry == nil || entry.length == 0) {
//        return NO;
//    }
    
    return [PPOLuhn validateString:entry];
}

@end
