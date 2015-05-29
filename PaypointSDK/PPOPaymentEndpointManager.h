//
//  PPOEndpointManager.h
//  Paypoint
//
//  Created by Robert Nash on 20/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPOPaymentEndpointManager : NSObject

-(NSURL*)urlForSimplePayment:(NSString*)installationID withBaseURL:(NSURL*)baseURL;
-(NSURL*)urlForPaymentWithID:(NSString*)paymentIdentifier withInst:(NSString*)installationID withBaseURL:(NSURL*)baseURL;
-(NSURL*)urlForResumePaymentWithInstallationID:(NSString*)installationID transactionID:(NSString*)transID withBaseURL:(NSURL*)baseURL;

@end
