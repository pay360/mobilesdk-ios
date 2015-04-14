//
//  PPOOutcomeManager.h
//  Paypoint
//
//  Created by Robert Nash on 14/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOOutcome.h"

@interface PPOOutcomeManager : NSObject

+(PPOOutcome*)handleResponse:(NSData*)responseData withError:(NSError*)error;

@end
