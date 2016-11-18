//
//  PPOPrivateError.h
//  Pay360
//
//  Created by Robert Nash on 08/06/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import "PPOSDKMacros.h"

PPOSDK_EXTERN NSString *const PPOPrivateErrorDomain;

typedef NS_ENUM(NSInteger, PPOPrivateError) {
    
    PPOPrivateErrorNotIntitialised = -1,
    
    PPOPrivateErrorBadRequest = 0,
        
    PPOPrivateErrorPaymentSuspendedForThreeDSecure,
    
    PPOPrivateErrorPaymentSuspendedForClientRedirect,
        
    PPOPrivateErrorProcessingThreeDSecure,
    
    PPOPrivateErrorThreeDSecureTimedOut,
    
};
