//
//  PPOWebViewControllerDelegate.h
//  Paypoint
//
//  Created by Robert Nash on 08/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "ThreeDSecureProtocol.h"

@class PPORedirect;
@class PPOPaymentEndpointManager;
@class PPOOutcome;
@interface PPOWebViewControllerDelegate : NSObject

-(instancetype)initWithSession:(NSURLSession*)session
                  withRedirect:(PPORedirect *)redirect
           withEndpointManager:(PPOPaymentEndpointManager *)manager
                withCompletion:(void(^)(PPOOutcome*))completion;

@end
