//
//  PPOCustomField.h
//  Pay360
//
//  Created by Robert Nash on 19/05/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 @class PPOCustomField
 @discussion An instance of this class represents a custom field.
 */
@interface PPOCustomField : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, strong) NSNumber *isTransient;

/*!
@discussion A convenience method for building an NSDictionary representation of the assigned values of each property listed in this class.
@return An NSDictionary representation of assigned values. The NSDictionary instance will be valid for JSON serialisation using the NSJSONSerialization parser in Foundation.framework.
 */
-(NSDictionary*)jsonObjectRepresentation;

@end
