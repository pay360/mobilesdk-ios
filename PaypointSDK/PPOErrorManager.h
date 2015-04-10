//
//  PPOErrorManager.h
//  Paypoint
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOError.h"
#import "PPOOutcome.h"

@interface PPOErrorManager : NSObject

+(PPOOutcome*)determineError:(NSError**)paypointError inResponse:(NSData*)responseData;

@end
