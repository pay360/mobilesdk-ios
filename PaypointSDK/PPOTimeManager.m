//
//  PPOTimeManager.m
//  Paypoint
//
//  Created by Robert Nash on 14/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
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
        
        // Time zones created with this never have daylight savings and the
        // offset is constant no matter the date;
        // Sidenote: the NAME and ABBREVIATION do NOT follow the POSIX convention (of minutes-west).
        NSTimeZone *timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        
        [_formatter setTimeZone:timeZone];
        
    }
    return _formatter;
}

-(NSDate*)dateFromString:(NSString*)date {
    return [self.formatter dateFromString:date];
}

@end
