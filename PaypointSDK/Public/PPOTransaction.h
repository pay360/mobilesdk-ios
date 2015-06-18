//
//  PPOTransaction.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
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
@property (nonatomic, strong) NSNumber *isDeferred;

/*!
@discussion A convenience method for building a plist of assigned values.
@return A plist of assigned values. The NSDictionary instance will be valid for JSON serialisation using the NSJSONSerialization parser in Foundation.framework.
 */
-(NSDictionary*)jsonObjectRepresentation;

@end
