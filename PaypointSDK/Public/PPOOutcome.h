//
//  PPOOutcome.h
//  Paypoint
//
//  Created by Robert Nash on 10/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOError.h"
#import "PPOPayment.h"

/*!
@class PPOOutcome
@discussion An instance of PPOOutcome represents the completion of a payment event, or the completion of a query made about an existing payment. A failed or incomplete payment will have an associated NSError. Any error found should have it's error domain and error code examined.
 */
@interface PPOOutcome : NSObject
@property (nonatomic, strong) PPOPayment *payment;
@property (nonatomic, strong) NSNumber *amount;
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *merchantRef;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *lastFour;
@property (nonatomic, strong) NSString *cardUsageType;
@property (nonatomic, strong) NSString *cardScheme;
@property (nonatomic, strong) NSSet *customFields;
@property (nonatomic, strong) NSError *error;
@end
