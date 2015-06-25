//
//  PPOErrorManager.m
//  Paypoint
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOErrorManager.h"

@implementation PPOErrorManager

+(NSError*)parsePaypointReasonCode:(NSInteger)code {
    
    switch (code) {
            
        case 1:
            return [PPOErrorManager buildErrorForPrivateErrorCode:PPOPrivateErrorBadRequest];
            break;
            
        case 2:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorAuthenticationFailed];
            break;
            
        case 3:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorClientTokenExpired];
            break;
            
        case 4:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorUnauthorisedRequest];
            break;
            
        case 5:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorTransactionDeclined];
            break;
            
        case 6:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorServerFailure];
            break;
            
        case 7:
            return [PPOErrorManager buildErrorForPrivateErrorCode:PPOPrivateErrorPaymentSuspendedForThreeDSecure];
            break;
            
        case 8:
            return [PPOErrorManager buildErrorForPrivateErrorCode:PPOPrivateErrorPaymentSuspendedForClientRedirect];
            break;
            
        case 9:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorPaymentProcessing];
            break;
            
        case 10:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorPaymentNotFound];
            break;
            
        default:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorUnexpected];
            break;
    }
    
}

+(NSError*)buildErrorForPrivateErrorCode:(PPOPrivateError)code {
    
    switch (code) {
            
        case PPOPrivateErrorBadRequest: {
            return [NSError errorWithDomain:PPOPrivateErrorDomain
                                       code:PPOPrivateErrorBadRequest
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The request was not well formed", @"Networking error")
                                              }
                    ];
        }
            break;
            
        case PPOPrivateErrorPaymentSuspendedForThreeDSecure: {
            return [NSError errorWithDomain:PPOPrivateErrorDomain
                                       code:PPOPrivateErrorPaymentSuspendedForThreeDSecure
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Payment currently suspended awaiting 3D Secure processing.", @"Feedback message for payment status")
                                              }
                    ];
        }
            break;
            
        case PPOPrivateErrorPaymentSuspendedForClientRedirect: {
            return [NSError errorWithDomain:PPOPrivateErrorDomain
                                       code:PPOPrivateErrorPaymentSuspendedForClientRedirect
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Payment currently suspended awaiting client redirect.", @"Feedback message for payment status")
                                              }
                    ];
        }
            break;
            
        case PPOPrivateErrorProcessingThreeDSecure: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPrivateErrorProcessingThreeDSecure
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"There has been an error processing your payment via 3D secure.", @"Failure message for 3D secure payment failure")
                                              }
                    ];
        } break;
            
        case PPOPrivateErrorThreeDSecureTimedOut: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPrivateErrorThreeDSecureTimedOut
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"3D secure timed out.", @"Failure message for 3D secure payment failure")
                                              }
                    ];
        } break;
            
        default: return nil; break;
    }
    
}

+(NSError*)buildErrorForPaymentErrorCode:(PPOPaymentError)code {
    
    switch (code) {
            
        case PPOPaymentErrorMasterSessionTimedOut: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorMasterSessionTimedOut
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Payment session timedout", @"Failure message for card validation")
                                              }
                    ];
        } break;
            
        case PPOPaymentErrorTransactionDeclined: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorTransactionDeclined
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Transaction declined", @"Feedback message for payment status")
                                              }
                    ];
        } break;
            
        case PPOPaymentErrorThreeDSecureTransactionProcessingFailed: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorThreeDSecureTransactionProcessingFailed
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Payment abandoned as failed to complete 3D Secure.", @"Feedback message for payment status")
                                              }
                    ];
        }
            break;
            
        case PPOPaymentErrorAuthenticationFailed: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorAuthenticationFailed
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The presented API token was not valid, or the wrong type of authentication was used", @"Failure message for authentication")
                                              }
                    ];
        } break;
            
        case PPOPaymentErrorPaymentProcessing: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorPaymentProcessing
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Transaction in progress", @"Status message for payment status check")
                                              }
                    ];
        } break;
            
        case PPOPaymentErrorServerFailure: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorServerFailure
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"There was an error from the server at Paypoint", @"Generic paypoint server error failure message")
                                              }
                    ];
        } break;
            
        case PPOPaymentErrorClientTokenExpired: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorClientTokenExpired
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The supplied bearer token has expired", @"Failure message for payment error")
                                              }
                    ];
        } break;
            
        case PPOPaymentErrorClientTokenInvalid: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorClientTokenInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The supplied bearer token is invalid", @"Failure message for a transaction validation check")
                                              }
                    ];
        } break;
            
        case PPOPaymentErrorUnauthorisedRequest: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorUnauthorisedRequest
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The supplied token does not have sufficient permissions", @"Failure message for account restriction")
                                              }
                    ];
        } break;
            
        case PPOPaymentErrorUnexpected: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorUnexpected
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"There has been an unknown error.", @"Failure message for payment failure")
                                              }
                    ];
        } break;
            
        case PPOPaymentErrorPaymentNotFound: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorPaymentNotFound
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"This payment did not complete or is not known.", @"Failure message for payment status")
                                              }
                    ];
        } break;
            
        case PPOPaymentErrorUserCancelledThreeDSecure: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorUserCancelledThreeDSecure
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"User cancelled 3D secure.", @"Failure message for 3D secure payment failure")
                                              }
                    ];
        } break;
            
        case PPOPaymentErrorPaymentManagerOccupied: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorPaymentManagerOccupied
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Payment manager occupied. Please wait until current payment finishes.", @"Failure message for 3D secure payment failure")
                                              }
                    ];
        } break;
            
        default: return nil; break;
    }
    
}

+(NSError*)buildErrorForValidationErrorCode:(PPOLocalValidationError)code {
    
    switch (code) {
            
        case PPOLocalValidationErrorCardExpiryDateExpired:
            return [NSError errorWithDomain:PPOLocalValidationErrorDomain
                                       code:PPOLocalValidationErrorCardExpiryDateExpired
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Expiry date is in the past", @"Failure message for card validation")
                                              }
                    ];
            break;
            
        case PPOLocalValidationErrorSuppliedBaseURLInvalid: {
            return [NSError errorWithDomain:PPOLocalValidationErrorDomain
                                       code:PPOLocalValidationErrorSuppliedBaseURLInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"PPOPaymentManager is missing a base URL", @"Failure message for BaseURL check")
                                              }
                    ];
        } break;
            
        case PPOLocalValidationErrorInstallationIDInvalid: {
            return [NSError errorWithDomain:PPOLocalValidationErrorDomain
                                       code:PPOLocalValidationErrorInstallationIDInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The installation ID is missing", @"Failure message for credentials check")
                                              }
                    ];
        } break;
            
        case PPOLocalValidationErrorCardPanInvalid: {
            return [NSError errorWithDomain:PPOLocalValidationErrorDomain
                                       code:PPOLocalValidationErrorCardPanInvalid
                                   userInfo:@{ //Description as per BLU-15022
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Invalid card number. Must be numbers only.", @"Failure message for a card validation check")
                                              }
                    ];
        } break;
            
        case PPOLocalValidationErrorCVVInvalid: {
            return [NSError errorWithDomain:PPOLocalValidationErrorDomain
                                       code:PPOLocalValidationErrorCVVInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Invalid CVV.", @"Failure message for a card validation check")
                                              }
                    ];
        } break;
            
        case PPOLocalValidationErrorCardExpiryDateInvalid: {
            return [NSError errorWithDomain:PPOLocalValidationErrorDomain
                                       code:PPOLocalValidationErrorCardExpiryDateInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Invalid expiry date. Must be YY MM.", @"Failure message for a card validation check")
                                              }
                    ];
        } break;
            
        case PPOLocalValidationErrorCurrencyInvalid: {
            return [NSError errorWithDomain:PPOLocalValidationErrorDomain
                                       code:PPOLocalValidationErrorCurrencyInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The specified currency is invalid", @"Failure message for a transaction validation check")
                                              }
                    ];
        } break;
            
        case PPOLocalValidationErrorPaymentAmountInvalid: {
            return [NSError errorWithDomain:PPOLocalValidationErrorDomain
                                       code:PPOLocalValidationErrorPaymentAmountInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Payment amount is invalid", @"Failure message for a transaction validation check")
                                              }
                    ];
        } break;
            
        case PPOLocalValidationErrorCredentialsNotFound: {
            return [NSError errorWithDomain:PPOLocalValidationErrorDomain
                                       code:PPOLocalValidationErrorCredentialsNotFound
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Credentials not supplied", @"Failure message for payment parameters integrity check")
                                              }
                    ];
        } break;
            
        default: return nil; break;
    }

}

+(NSError*)buildCustomerFacingErrorFromError:(NSError *)error {
    
    if ([error.domain isEqualToString:PPOPrivateErrorDomain]) {
        return [PPOErrorManager buildCustomerFacingErrorFromPrivateError:error];
    } else if ([error.domain isEqualToString:NSURLErrorDomain]) {
        return [PPOErrorManager buildCustomerFacingErrorFromNSURLError:error];
    } else {
        return error;
    }
    
    return nil;
}

+(NSError*)buildCustomerFacingErrorFromNSURLError:(NSError*)error {
    
    if (![error.domain isEqualToString:NSURLErrorDomain]) {
        return nil;
    }
    
    if (error.code == NSURLErrorCancelled) {
        return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorMasterSessionTimedOut];
    }
    
    return nil;
}

+(NSError*)buildCustomerFacingErrorFromPrivateError:(NSError*)error {
    
    if (![error.domain isEqualToString:PPOPrivateErrorDomain]) {
        return nil;
    }
    
    switch (error.code) {
            
        case PPOPrivateErrorBadRequest:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorUnexpected];
            break;
            
        case PPOPrivateErrorPaymentSuspendedForThreeDSecure:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorThreeDSecureTransactionProcessingFailed];
            break;
            
        case PPOPrivateErrorPaymentSuspendedForClientRedirect:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorThreeDSecureTransactionProcessingFailed];
            break;
            
        case PPOPrivateErrorProcessingThreeDSecure:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorUnexpected];
            break;
            
        case PPOPrivateErrorThreeDSecureTimedOut:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorMasterSessionTimedOut];
            break;
            
        default:
            return [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorUnexpected];
            break;
            
    }
    
    return nil;
}

+(BOOL)isSafeToRetryPaymentWithError:(NSError *)error {
    
    if ([error.domain isEqualToString:PPOLocalValidationErrorDomain]) {
        
        return YES;
        
    } else if ([error.domain isEqualToString:PPOPrivateErrorDomain]) {
        
        return NO;
        
    } else if ([error.domain isEqualToString:PPOPaymentErrorDomain]) {
        
        return [PPOErrorManager isSafeToRetryPaymentWithPaymentError:error];
        
    }
    
    return NO;
}

+(BOOL)isSafeToRetryPaymentWithPaymentError:(NSError*)error {
    
    if (![error.domain isEqualToString:PPOPaymentErrorDomain]) {
        return NO;
    }
    
    return [@[
              @(PPOPaymentErrorClientTokenExpired),
              @(PPOPaymentErrorClientTokenInvalid),
              @(PPOPaymentErrorUnauthorisedRequest),
              @(PPOPaymentErrorTransactionDeclined),
              @(PPOPaymentErrorAuthenticationFailed),
              @(PPOPaymentErrorPaymentNotFound)
              ] containsObject:@(error.code)];

}

@end
