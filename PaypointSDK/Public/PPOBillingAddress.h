//
//  PPOBillingAddress.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
@class PPOBillingAddress
@discussion An instance of this class represents a billing address.
 */
@interface PPOBillingAddress : NSObject

@property (nonatomic, strong) NSString *line1;
@property (nonatomic, strong) NSString *line2;
@property (nonatomic, strong) NSString *line3;
@property (nonatomic, strong) NSString *line4;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *region;
@property (nonatomic, strong) NSString *postcode;
@property (nonatomic, strong) NSString *countryCode;

/*!
@discussion A convenience method for building an NSDictionary representation of the assigned values of each property listed in this class.
@return A plist of assigned values. The NSDictionary instance will be valid for JSON serialisation using the NSJSONSerialization parser in Foundation.framework.
 */
-(NSDictionary*)jsonObjectRepresentation;

@end
