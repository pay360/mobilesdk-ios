//
//  PPOErrorManager.m
//  Paypoint
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOErrorManager.h"
#import "PPOInternalError.h"

@implementation PPOErrorManager

+(NSError *)parsePaypointReasonCode:(NSInteger)reasonCode {
    
    NSError *error;
    
    switch (reasonCode) {
        case 1: {
            error = [PPOErrorManager buildErrorForPrivateError:PPOPrivateErrorBadRequest];
        } break;
        case 2: {
            error = [PPOErrorManager buildErrorForPrivateError:PPOPrivateErrorAuthenticationFailed];
        } break;
        case 3: {
            error = [PPOErrorManager buildErrorForPaymentError:PPOPaymentErrorClientTokenExpired];
        } break;
        case 4: {
            error = [PPOErrorManager buildErrorForPaymentError:PPOPaymentErrorUnauthorisedRequest];
        } break;
        case 5: {
            error = [PPOErrorManager buildErrorForPaymentError:PPOPaymentErrorTransactionDeclined];
        } break;
        case 6: {
            error = [PPOErrorManager buildErrorForPaymentError:PPOPaymentErrorServerFailure];
        } break;
        case 7: {
            error = [PPOErrorManager buildErrorForPrivateError:PPOPrivateErrorPaymentSuspendedForThreeDSecure];
        } break;
        case 8: {
            error = [PPOErrorManager buildErrorForPrivateError:PPOPrivateErrorPaymentSuspendedForClientRedirect];
        } break;
        case 9: {
            error = [PPOErrorManager buildErrorForPaymentError:PPOPaymentErrorPaymentProcessing];
        } break;
        case 10: {
            error = [PPOErrorManager buildErrorForPaymentError:PPOPaymentErrorPaymentNotFound];
        } break;
            
        default:
            break;
    }
        
    return error;
    
}

+(NSError*)buildErrorForPrivateError:(PPOPrivateError)code {
    
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
            
        case PPOPrivateErrorAuthenticationFailed: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPrivateErrorAuthenticationFailed
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Authentication failed", @"Failure message for authentication")
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
            
        default:
            break;
    }
    
    return nil;
}

+(NSError*)buildErrorForPaymentError:(PPOPaymentError)code {
    
    switch (code) {
            
        case PPOPaymentErrorMasterSessionTimedOut: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorMasterSessionTimedOut
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Payment session timedout", @"Failure message for card validation")
                                              }
                    ];
        }
            break;
            
        case PPOPaymentErrorTransactionDeclined: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorTransactionDeclined
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Transaction declined.", @"Feedback message for payment status")
                                              }
                    ];
        }
            break;
            
        case PPOPaymentErrorPaymentProcessing:
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorPaymentProcessing
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Transaction in progress", @"Status message for payment status check")
                                              }
                    ];
            break;
            
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
            
        case PPOPaymentErrorTransactionProcessingFailed: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorTransactionProcessingFailed
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The transaction failed to process correctly", @"Failure message for payment failure")
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
        }
            break;
            
        case PPOPaymentErrorUserCancelled: {
            return [NSError errorWithDomain:PPOPaymentErrorDomain
                                       code:PPOPaymentErrorUserCancelled
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
        }
            break;
            
        default: return nil; break;
    }
    
}

+(NSError*)buildErrorForValidationError:(PPOLocalValidationError)code {
    
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
            
        default:
            break;
    }
    
    return nil;
}

@end
