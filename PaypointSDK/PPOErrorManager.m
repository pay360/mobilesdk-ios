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

+(NSError*)errorForCode:(PPOErrorCode)code {
    
    switch (code) {
        case PPOErrorSuppliedBaseURLInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorSuppliedBaseURLInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"PPOPaymentManager is missing a base URL", @"Failure message for BaseURL check")
                                              }
                    ];
        } break;
        case PPOErrorInstallationIDInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorInstallationIDInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The installation ID is missing", @"Failure message for credentials check")
                                              }
                    ];
        } break;
        case PPOErrorCardPanLengthInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorCardPanLengthInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Pan number length is invalid", @"Failure message for a card validation check")
                                              }
                    ];
        } break;
        case PPOErrorLuhnCheckFailed: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorLuhnCheckFailed
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Pan number failed Luhn validation", @"Failure message for a card validation check")
                                              }
                    ];
        } break;
        case PPOErrorCVVInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorCVVInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Card CVV is invalid", @"Failure message for a card validation check")
                                              }
                    ];
        } break;
        case PPOErrorCardExpiryDateInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorCardExpiryDateInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Expiry date is invalid", @"Failure message for a card validation check")
                                              }
                    ];
        } break;
        case PPOErrorCurrencyInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorCurrencyInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The specified currency is invalid", @"Failure message for a transaction validation check")
                                              }
                    ];
        } break;
        case PPOErrorPaymentAmountInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorPaymentAmountInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Payment amount is invalid", @"Failure message for a transaction validation check")
                                              }
                    ];
        } break;
        case PPOErrorCredentialsNotFound: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorCredentialsNotFound
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Credentials not supplied", @"Failure message for payment parameters integrity check")
                                              }
                    ];
        } break;
        case PPOErrorServerFailure: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorServerFailure
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"There was an error from the server at Paypoint", @"Generic paypoint server error failure message")
                                              }
                    ];
        } break;
        case PPOErrorClientTokenExpired: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorClientTokenExpired
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The supplied bearer token has expired", @"Failure message for payment error")
                                              }
                    ];
        } break;
        case PPOErrorClientTokenInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorUnauthorisedRequest
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The supplied token is invalid", @"Failure message for a transaction validation check")
                                              }
                    ];
        } break;
        case PPOErrorUnauthorisedRequest: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorUnauthorisedRequest
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The supplied token does not have sufficient permissions", @"Failure message for account restriction")
                                              }
                    ];
        } break;
        case PPOErrorTransactionProcessingFailed: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorTransactionProcessingFailed
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The transaction failed to process correctly", @"Failure message for payment failure")
                                              }
                    ];
        } break;
        case PPOErrorUnknown: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorUnknown
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"There has been an unknown error.", @"Failure message for payment failure")
                                              }
                    ];
        } break;
        case PPOErrorProcessingThreeDSecure: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorProcessingThreeDSecure
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"There has been an error processing your payment via 3D secure.", @"Failure message for 3D secure payment failure")
                                              }
                    ];
        } break;
        case PPOErrorThreeDSecureTimedOut: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorThreeDSecureTimedOut
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"3D secure timed out.", @"Failure message for 3D secure payment failure")
                                              }
                    ];
        } break;
        case PPOErrorUserCancelled: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorUserCancelled
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"User cancelled 3D secure.", @"Failure message for 3D secure payment failure")
                                              }
                    ];
        } break;
            
        default: return nil; break;
    }
    
}

@end
