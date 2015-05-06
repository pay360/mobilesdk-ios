//
//  PPOPaymentsDispatchManager.h
//  Paypoint
//
//  Created by Robert Nash on 20/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOOutcome.h"
#import "PPOCredentials.h"

@interface PPOPaymentsDispatchManager : NSObject

@property (nonatomic, strong, readonly) NSOperationQueue *payments;

-(void)dispatchRequest:(NSURLRequest*)request
           withTimeout:(CGFloat)timeout
       withCredentials:(PPOCredentials*)credentials
        withCompletion:(void (^)(PPOOutcome *outcome, NSError *error))completion;

@end
