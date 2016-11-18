//
//  PPOWebViewControllerDelegate.h
//  Pay360
//
//  Created by Robert Nash on 08/06/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import "ThreeDSecureProtocol.h"

@class PPORedirect;
@class PPOPaymentEndpointManager;
@class PPOOutcome;
@interface ThreeDSecureDelegate : NSObject <ThreeDSecureProtocol>

-(instancetype)initWithSession:(NSURLSession*)session
                  withRedirect:(PPORedirect *)redirect
           withEndpointManager:(PPOPaymentEndpointManager *)manager
                withCompletion:(void(^)(PPOOutcome*))completion;

@end
