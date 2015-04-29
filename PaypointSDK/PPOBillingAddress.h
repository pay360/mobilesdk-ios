//
//  PPOBillingAddress.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPOBillingAddress : NSObject
@property (nonatomic, strong) NSString *line1;
@property (nonatomic, strong) NSString *line2;
@property (nonatomic, strong) NSString *line3;
@property (nonatomic, strong) NSString *line4;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *region;
@property (nonatomic, strong) NSString *postcode;
@property (nonatomic, strong) NSString *countryCode;

-(NSDictionary*)jsonObjectRepresentation;

@end
