//
//  PPOCustomer.h
//  Pay360
//
//  Created by Robert Nash on 19/05/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
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
@discussion A convenience method for building an NSDictionary representation of the assigned values of each property listed in this class.
@return An NSDictionary representation of assigned values. The NSDictionary instance will be valid for JSON serialisation using the NSJSONSerialization parser in Foundation.framework.
 */
-(NSDictionary*)jsonObjectRepresentation;

@end
