//
//  PPOCustomer.m
//  Pay360
//
//  Created by Robert Nash on 19/05/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import "PPOCustomer.h"

@implementation PPOCustomer

-(NSDictionary*)jsonObjectRepresentation {
    id email = ([self cleanString:self.email]) ?: [NSNull null];
    id dateOfBirth = ([self cleanString:self.dateOfBirth]) ?: [NSNull null];
    id telephone = ([self cleanString:self.telephone]) ?: [NSNull null];
    
    return @{
             @"email": email,
             @"dob": dateOfBirth,
             @"telephone": telephone
             };
}

-(NSString*)cleanString:(NSString*)string {
    return [string stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
