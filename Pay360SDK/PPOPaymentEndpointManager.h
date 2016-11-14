//
//  PPOEndpointManager.h
//  Pay360
//
//  Created by Robert Nash on 20/04/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPOPaymentEndpointManager : NSObject

@property (nonatomic, strong, readonly) NSURL *baseURL;

-(instancetype)initWithBaseURL:(NSURL*)baseURL;
-(NSURL*)urlForSimplePayment:(NSString*)installationID;
-(NSURL*)urlForPaymentWithID:(NSString*)paymentIdentifier withInst:(NSString*)installationID;
-(NSURL*)urlForResumePaymentWithInstallationID:(NSString*)installationID transactionID:(NSString*)transID;

@end
