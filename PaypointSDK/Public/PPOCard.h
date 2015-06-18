//
//  PPOCard.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
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
 @discussion Must be expressed as 'MM YY'
 */
@property (nonatomic, strong) NSString *expiry;
@property (nonatomic, strong) NSString *cardHolderName;

/*!
@discussion A convenience method for building a plist of assigned values.
@return A plist of assigned values. The NSDictionary instance will be valid for JSON serialisation using the NSJSONSerialization parser in Foundation.framework.
 */
-(NSDictionary*)jsonObjectRepresentation;

@end
