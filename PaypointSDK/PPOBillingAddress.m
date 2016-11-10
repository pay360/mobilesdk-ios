//
//  PPOBillingAddress.m
//  Pay360
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import "PPOBillingAddress.h"

@implementation PPOBillingAddress

-(NSDictionary*)jsonObjectRepresentation {
    id line1 = (self.line1) ?: [NSNull null];
    id line2 = (self.line2) ?: [NSNull null];
    id line3 = (self.line3) ?: [NSNull null];
    id line4 = (self.line4) ?: [NSNull null];
    id city = (self.city) ?: [NSNull null];
    id region = (self.region) ?: [NSNull null];
    id postcode = (self.postcode) ?: [NSNull null];
    id countryCode = (self.countryCode) ?: [NSNull null];
    
    return @{
             @"line1": line1,
             @"line2": line2,
             @"line3": line3,
             @"line4": line4,
             @"city": city,
             @"region": region,
             @"postcode": postcode,
             @"countryCode": countryCode,
             };
}

@end
