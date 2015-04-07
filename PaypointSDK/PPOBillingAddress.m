//
//  PPOBillingAddress.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOBillingAddress.h"

@interface PPOBillingAddress ()
@property (nonatomic, strong, readwrite) NSString *line1;
@property (nonatomic, strong, readwrite) NSString *line2;
@property (nonatomic, strong, readwrite) NSString *line3;
@property (nonatomic, strong, readwrite) NSString *line4;
@property (nonatomic, strong, readwrite) NSString *city;
@property (nonatomic, strong, readwrite) NSString *region;
@property (nonatomic, strong, readwrite) NSString *postcode;
@property (nonatomic, strong, readwrite) NSString *countryCode;
@end

@implementation PPOBillingAddress

-(instancetype)initWithFirstLine:(NSString*)line1 withSecondLine:(NSString*)line2 withThirdLine:(NSString*)line3 withFourthLine:(NSString*)line4 withCity:(NSString*)city withRegion:(NSString*)region withPostcode:(NSString*)postcode withCountryCode:(NSString*)countryCode {
    self = [super init];
    if (self) {
        _line1 = line1;
        _line2 = line2;
        _line3 = line3;
        _line4 = line4;
        _city = city;
        _region = region;
        _postcode = postcode;
        _countryCode = countryCode;
    }
    return self;
}

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
