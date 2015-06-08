//
//  PPOInternalError.h
//  Paypoint
//
//  Created by Robert Nash on 08/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const PPOPrivateErrorDomain;

typedef NS_ENUM(NSInteger, PPOPrivateError) {
    
    PPOPrivateErrorNotIntitialised = -1,
    
    PPOPrivateErrorBadRequest = 0,
    
    PPOPrivateErrorAuthenticationFailed,
    
    PPOPrivateErrorPaymentSuspendedForThreeDSecure,
    
    PPOPrivateErrorPaymentSuspendedForClientRedirect,
    
    PPOPrivateErrorProcessingThreeDSecure,
    
    PPOPrivateErrorThreeDSecureTimedOut,
    
};
