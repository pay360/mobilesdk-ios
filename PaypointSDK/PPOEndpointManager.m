//
//  PPOEndpointManager.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOEndpointManager.h"

@implementation PPOEndpointManager

+(NSURL*)simplePayment:(NSString*)installationID {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:5000/mobileapi/transactions/%@/payment", installationID]];
}

@end
