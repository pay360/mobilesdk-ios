//
//  PPOOutcomeBuilder.h
//  Paypoint
//
//  Created by Robert Nash on 12/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOOutcome.h"

@interface PPOOutcomeBuilder : NSObject

+(PPOOutcome*)outcomeWithData:(NSDictionary*)data
                    withError:(NSError*)error
                   forPayment:(PPOPayment *)payment;

@end
