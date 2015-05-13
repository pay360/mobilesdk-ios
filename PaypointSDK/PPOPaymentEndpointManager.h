//
//  PPOEndpointManager.h
//  Paypoint
//
//  Created by Robert Nash on 20/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPOPaymentEndpointManager : NSObject

-(NSURL*)simplePayment:(NSString*)installationID withBaseURL:(NSURL*)baseURL;
-(NSURL*)resumePaymentWithInstallationID:(NSString*)installationID transactionID:(NSString*)transID withBaseURL:(NSURL*)baseURL;

@end
