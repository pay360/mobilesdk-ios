//
//  PPOEndpointManager.h
//  Paypoint
//
//  Created by Robert Nash on 20/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentBaseURLManager.h"

@interface PPOPaymentEndpointManager : PPOPaymentBaseURLManager

-(NSURL*)simplePayment:(NSString*)installationID withBaseURL:(NSURL*)baseURL;

@end
