//
//  PPOErrorManager.m
//  Paypoint
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOErrorManager.h"

@implementation PPOErrorManager

+(NSString*)errorDomainForReasonCode:(NSInteger)reasonCode {
    
    NSString *domain;
    
    switch (reasonCode) { //A reason code is a Paypoint reason code.
            
        case 0: //Success, so should not be considered as needing an 'error domain' at all
            break;
            
        default:
            domain = PPOPaypointSDKErrorDomain; // Use this domain for everything. Even if reason code is unknown.
            break;
    }
    
    return domain;
}

+(PPOErrorCode)errorCodeForReasonCode:(NSInteger)reasonCode {
    
    PPOErrorCode code = PPOErrorUnknown;
    
    switch (reasonCode) {
        case 1: code = PPOErrorBadRequest; break;
        case 2: code = PPOErrorAuthenticationFailed; break;
        case 3: code = PPOErrorClientTokenExpired; break;
        case 4: code = PPOErrorUnauthorisedRequest; break;
        case 5: code = PPOErrorTransactionProcessingFailed; break;
        case 6: code = PPOErrorServerFailure; break;
            
        default:
            break;
    }
    
    return code;
    
}

@end
