//
//  PPOCard.h
//  Pay360
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
@class PPOCard
@discussion An instance of this class represents a credit card.
 */
@interface PPOCard : NSObject
@property (nonatomic, strong) NSString *pan;

/*!
@discussion Must be 3 or 4 digits.
 */
@property (nonatomic, strong) NSString *cvv;

/*!
 @discussion Must be expressed as 'MMYY'
 */
@property (nonatomic, strong) NSString *expiry;
@property (nonatomic, strong) NSString *cardHolderName;

/*!
@discussion A convenience method for building an NSDictionary representation of the assigned values of each property listed in this class.
@return A data structore of assigned values in the form of key value pairs. The NSDictionary instance will be valid for JSON serialisation using the NSJSONSerialization parser in Foundation.framework.
 */
-(NSDictionary*)jsonObjectRepresentation;

@end
