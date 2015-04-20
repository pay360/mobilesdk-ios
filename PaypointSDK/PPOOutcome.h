//
//  PPOOutcome.h
//  Paypoint
//
//  Created by Robert Nash on 10/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPOOutcome : NSObject

@property (nonatomic, strong, readonly) NSNumber *amount;
@property (nonatomic, strong, readonly) NSString *currency;
@property (nonatomic, strong, readonly) NSDate *date;
@property (nonatomic, strong, readonly) NSString *merchantRef;
@property (nonatomic, strong, readonly) NSString *type;
@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSNumber *reasonCode;
@property (nonatomic, strong, readonly) NSString *lastFour;
@property (nonatomic, strong, readonly) NSString *cardUsageType;
@property (nonatomic, strong, readonly) NSString *cardScheme;
@property (nonatomic, readonly) BOOL isSuccessful;

-(instancetype)initWithData:(NSDictionary*)data;

@end
