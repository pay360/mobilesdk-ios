//
//  PPOErrorManager.m
//  Paypoint
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOErrorManager.h"

@implementation PPOErrorManager

+(PPOOutcome*)determineError:(NSError**)paypointError inResponse:(NSData*)responseData {
    
    NSError *jsonError;
    
    id json = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&jsonError];
    
    if (jsonError && paypointError) {
        
        NSString *errorDomain = PPOPaypointSDKErrorDomain;
        PPOErrorCode code = PPOErrorServerFailure;
        NSDictionary *userInfo = @{
                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"JSON received from Paypoint is Invalid", @"Parsing error message")
                                   };
        
        *paypointError = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    }
    
    PPOOutcome *outcome = [[PPOOutcome alloc] initWithData:json];
    
    if (paypointError && outcome.reasonCode.integerValue > 0) {
        
        NSDictionary *userInfo;
        if (outcome.reasonMessage && outcome.reasonMessage.length > 0) {
            userInfo = @{NSLocalizedFailureReasonErrorKey: outcome.reasonMessage};
        }
        
        NSString *errorDomain = [PPOErrorManager errorDomainForReasonCode:outcome.reasonCode.integerValue];
        PPOErrorCode code = [PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue];
        
        *paypointError = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    }
    
    return outcome;
}

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
