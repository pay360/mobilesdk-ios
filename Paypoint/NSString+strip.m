//
//  NSString+strip.m
//  Paypoint
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "NSString+strip.h"

@implementation NSString (strip)

-(NSString*)stripWhitespace {
    return [self stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
