//
//  PPOWebFormDelegate.h
//  Pay360
//
//  Created by Robert Nash on 01/06/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPORedirect;
@class PPOOutcome;
@class PPOPaymentEndpointManager;
@class PPOCredentials;
@class PPORedirectManager;

@interface PPORedirectManager : NSObject

-(instancetype)initWithRedirect:(PPORedirect*)redirect
                    withSession:(NSURLSession*)session
            withEndpointManager:(PPOPaymentEndpointManager*)endpointManager
                 withCompletion:(void(^)(PPOOutcome *outcome))completion;

-(void)startRedirect;

@end
