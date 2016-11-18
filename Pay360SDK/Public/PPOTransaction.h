//
//  PPOTransaction.h
//  Pay360
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
@class PPOTransaction
@discussion An instance of this class represents a transaction. Set 'isDeferred' to 'YES' for pre-authentication.
 */
@interface PPOTransaction : NSObject
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSNumber *amount;
@property (nonatomic, strong) NSString *transactionDescription;
@property (nonatomic, strong) NSString *merchantRef;
@property (nonatomic, strong) NSNumber *isRecurring;
@property (nonatomic, strong) NSNumber *isDeferred;

/*!
@discussion A convenience method for building an NSDictionary representation of the assigned values of each property listed in this class.
@return An NSDictionary representation of assigned values. The NSDictionary instance will be valid for JSON serialisation using the NSJSONSerialization parser in Foundation.framework.
 */
-(NSDictionary*)jsonObjectRepresentation;

@end
