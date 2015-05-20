//
//  PPOTimeManager.h
//  Paypoint
//
//  Created by Robert Nash on 14/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOTimeManager : NSObject

-(NSDate*)dateFromString:(NSString*)date;
+(BOOL)cardExpiryDateExpired:(NSString*)expiry;

@end
