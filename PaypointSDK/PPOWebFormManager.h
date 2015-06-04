//
//  PPOWebFormDelegate.h
//  Paypoint
//
//  Created by Robert Nash on 01/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPORedirect;
@class PPOOutcome;
@class PPOPaymentEndpointManager;
@class PPOCredentials;
@class PPOWebFormManager;

@interface PPOWebFormManager : NSObject

-(instancetype)initWithRedirect:(PPORedirect*)redirect
                withCredentials:(PPOCredentials*)credentials
                    withSession:(NSURLSession*)session
            withEndpointManager:(PPOPaymentEndpointManager*)endpointManager
                    withOutcome:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler;

-(void)performResumeForRedirect:(PPORedirect*)redirect withCredentials:(PPOCredentials*)credentials;

@end
