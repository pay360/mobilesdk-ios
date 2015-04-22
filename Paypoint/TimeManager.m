//
//  TimeManager.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "TimeManager.h"

@implementation TimeManager

-(NSDateFormatter *)cardExpiryDateFormatter {
    if (_cardExpiryDateFormatter == nil) {
        _cardExpiryDateFormatter = [NSDateFormatter new];
        [_cardExpiryDateFormatter setDateFormat:@"MM YY"];
        [_cardExpiryDateFormatter setLocale:[TimeManager locale]];
    }
    return _cardExpiryDateFormatter;
}

+(NSArray*)expiryDatesFromDate:(NSDate*)now {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setYear:5];
    NSDate *endDate = [gregorian dateByAddingComponents:offsetComponents toDate:now options:NSCalendarWrapComponents];
    
    NSUInteger unitFlags = NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *comps = [gregorian components:unitFlags fromDate:now  toDate:endDate  options:NSCalendarWrapComponents];
    NSUInteger months = [comps month];
    
    NSMutableArray *dateCollector = [NSMutableArray new];
    
    NSDate *date;
    
    for (NSInteger i = 0; i < months; i++) {
        NSCalendar *currentCalendar = [NSCalendar currentCalendar];
        NSDateComponents *dateComponents = [currentCalendar components:
                                            NSCalendarUnitHour |
                                            NSCalendarUnitMinute |
                                            NSCalendarUnitYear |
                                            NSCalendarUnitMonth |
                                            NSCalendarUnitDay
                                            fromDate:now];
        dateComponents.month += (i+1);
        date = [currentCalendar dateFromComponents:dateComponents];
        if (date) [dateCollector addObject:date];
    }
    
    return [dateCollector copy];
}

+(NSLocale *)locale {
    return [NSLocale localeWithLocaleIdentifier:@"en_GB"];
}

@end
