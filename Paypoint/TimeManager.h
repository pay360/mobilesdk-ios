//
//  TimeManager.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimeManager : NSObject
@property (nonatomic, strong) NSDateFormatter *cardExpiryDateFormatter;

+(NSArray*)expiryDatesFromDate:(NSDate*)now;
+(NSLocale*)locale;

@end
