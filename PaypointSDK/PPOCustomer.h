//
//  PPOCustomer.h
//  Paypoint
//
//  Created by Robert Nash on 19/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class PPOCustomer
 @discussion An instance of this class represents a customer.
 */
@interface PPOCustomer : NSObject
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *dateOfBirth;
@property (nonatomic, copy) NSString *telephone;

/*!
 A convenience method for building a plist of assigned values.
 @return A plist of assigned values. The NSDictionary instance will be valid for JSON serialisation using the NSJSONSerialization parser in Foundation.framework.
 */
-(NSDictionary*)jsonObjectRepresentation;

@end
