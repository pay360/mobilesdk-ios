//
//  PPOBillingAddress.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOBillingAddress : NSObject
@property (nonatomic, strong, readonly) NSString *line1;
@property (nonatomic, strong, readonly) NSString *line2;
@property (nonatomic, strong, readonly) NSString *line3;
@property (nonatomic, strong, readonly) NSString *line4;
@property (nonatomic, strong, readonly) NSString *city;
@property (nonatomic, strong, readonly) NSString *region;
@property (nonatomic, strong, readonly) NSString *postcode;
@property (nonatomic, strong, readonly) NSString *countryCode;

-(instancetype)initWithFirstLine:(NSString*)line1 withSecondLine:(NSString*)line2 withThirdLine:(NSString*)line3 withFourthLine:(NSString*)line4 withCity:(NSString*)city withRegion:(NSString*)region withPostcode:(NSString*)postcode withCountryCode:(NSString*)countryCode; //Designated Initialiser

-(NSDictionary*)jsonObjectRepresentation;

@end
