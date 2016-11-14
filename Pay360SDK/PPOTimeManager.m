//
//  PPOTimeManager.m
//  Pay360
//
//  Created by Robert Nash on 14/04/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import "PPOTimeManager.h"

@interface PPOTimeManager ()
@property (nonatomic, strong) NSDateFormatter *formatter;
@end

@implementation PPOTimeManager

-(NSDateFormatter *)formatter {
    if (_formatter == nil) {
        _formatter = [NSDateFormatter new];
        
        _formatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'";
        
        //In most cases the best locale to choose is en_US_POSIX,
        //a locale that's specifically designed to yield US English
        //results regardless of both user and system preferences.
        //en_US_POSIX is also invariant in time (if the US, at some
        //point in the future, changes the way it formats dates,
        //en_US will change to reflect the new behavior, but en_US_POSIX
        //will not), and between platforms (en_US_POSIX works the same on
        //iPhone OS as it does on OS X, and as it does on other platforms).
        _formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        //https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/DataFormatting/Articles/dfDateFormatting10_4.html#//apple_ref/doc/uid/TP40002369-SW13
        
        [_formatter setTimeZone:[PPOTimeManager timezone]];
        
    }
    return _formatter;
}

-(NSDate*)dateFromString:(NSString*)date {
    return [self.formatter dateFromString:date];
}

+(NSTimeZone*)timezone {
    // Time zones created with this never have daylight savings and the
    // offset is constant no matter the date;
    // Sidenote: the NAME and ABBREVIATION do NOT follow the POSIX convention (of minutes-west).
    return [NSTimeZone timeZoneForSecondsFromGMT:0];
}

+(BOOL)cardExpiryDateExpired:(NSString*)expiry {
    if (!expiry || expiry.length != 4) {
        return NO;
    }
    
    NSDate *currentDate = [NSDate date];
    
    NSString *m = [expiry substringToIndex:2];
    NSString *y = [PPOTimeManager buildCardExpiryYear:[expiry substringFromIndex:2]];
    NSDate *computedDate = [PPOTimeManager dateWithMonth:@(m.intValue) withYear:@(y.intValue)];
    
    return [currentDate compare:computedDate] == NSOrderedDescending;
}

+(NSDate*)dateWithMonth:(NSNumber*)m withYear:(NSNumber*)y {
    NSDate *computedDate;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    
    //The first moment of a given month is expressed as the first instance following the final moment of the previous month
    //e.g. 01 May 2015 is expressed as 2015-04-30 23:00:00 UTC
    //We bump the month by 1, so that we get the end of the month we want
    NSInteger monthInteger = m.intValue;
    NSInteger yearInteger = y.intValue;
    if (monthInteger == 12) {
        //Bumping the month would result in 13, which is invalid
        monthInteger = 1;
        yearInteger++;
    } else {
        monthInteger++;
    }
    
    NSNumber *month = @(monthInteger);
    NSNumber *year = @(yearInteger);
    [components setMonth:[month intValue]];
    [components setYear:[year intValue]];
    computedDate = [calendar dateFromComponents:components];
    return computedDate;
}

+(NSString*)buildCardExpiryYear:(NSString*)digit {
    NSInteger number = digit.intValue;
    if (number < 10) {
        return [NSString stringWithFormat:@"200%li", (long)number];
    } else {
        return [NSString stringWithFormat:@"20%li", (long)number];
    }
}

@end
