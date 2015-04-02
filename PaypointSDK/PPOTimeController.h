//
//  PPOTimeController.h
//  Paypoint
//
//  Created by Robert Nash on 24/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOTimeController : NSObject
@property (nonatomic, strong) NSDateFormatter *cardExpiryDateFormatter;

+(NSArray*)expiryDatesFromDate:(NSDate*)now;
+(NSLocale*)locale;

@end
