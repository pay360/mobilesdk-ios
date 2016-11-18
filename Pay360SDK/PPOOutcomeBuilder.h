//
//  PPOOutcomeBuilder.h
//  Pay360
//
//  Created by Robert Nash on 12/06/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import "PPOOutcome.h"

@interface PPOOutcomeBuilder : NSObject

+(PPOOutcome*)outcomeWithData:(NSDictionary*)data
                    withError:(NSError*)error
                   forPayment:(PPOPayment *)payment;

@end
