//
//  PPOFinancialService.m
//  Paypoint
//
//  Created by Robert Nash on 19/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOFinancialService.h"

@implementation PPOFinancialService

-(NSDictionary*)jsonObjectRepresentation {
    id dateOfBirth = ([self cleanString:self.dateOfBirth]) ?: [NSNull null];
    id surname = ([self cleanString:self.surname]) ?: [NSNull null];
    id accountNumber = (self.accountNumber) ? [self cleanString:self.accountNumber] : [NSNull null];
    id postCode = (self.postCode) ?: [NSNull null];
    
    return @{
             @"dateOfBirth": dateOfBirth,
             @"surname": surname,
             @"accountNumber": accountNumber,
             @"postCode": postCode
             };
}

-(NSString*)cleanString:(NSString*)string {
    return [string stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
