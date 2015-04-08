//
//  PPOEndpointManager.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOEndpointManager : NSObject

+(NSURL*)simplePayment:(NSString*)installationID;

@end
