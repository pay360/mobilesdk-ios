//
//  PPOError.m
//  Paypoint
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOSDKMacros.h"

PPOSDK_EXTERN NSString *const PPOPaymentErrorDomain;
PPOSDK_EXTERN NSString *const PPOLocalValidationErrorDomain;

/*!
   @discussion Errors relating to a payment.
   @typedef PPOPaymentError
   @constant PPOPaymentErrorNotInitialised Error not yet initialised.
   @constant PPOPaymentErrorUnexpected Represents an unexpected error.
   @constant PPOPaymentValidationError An invalid parameter was supplied in your payment.
   @constant PPOPaymentErrorClientTokenExpired The supplied bearer token has expired.
   @constant PPOPaymentErrorClientTokenInvalid The supplied bearer token is invalid.
   @constant PPOPaymentErrorUnauthorisedRequest The supplied token does not have sufficient permissions to access the specified feature.
   @constant PPOPaymentErrorThreeDSecureTransactionProcessingFailed The transaction was successfully submitted but did not complete three D secure validation.
   @constant PPOPaymentErrorServerFailure An internal server error occurred at paypoint.
   @constant PPOPaymentErrorMasterSessionTimedOut The payment session timed out. This is the timeout that is passed into the payment manager.
   @constant PPOPaymentErrorUserCancelledThreeDSecure User cancelled 3D Secure.
   @constant PPOPaymentErrorPaymentProcessing The payment is currently in flight.
   @constant PPOPaymentErrorTransactionDeclined The transaction was declined.
   @constant PPOPaymentErrorAuthenticationFailed The presented API token was not valid the wrong type of authentication was used.
   @constant PPOPaymentErrorPaymentNotFound The transaction or operation was not found.
   @constant PPOPaymentErrorPaymentManagerOccupied A payment currently occupies the payment manager. Only one payment allowed per unit time.
 */
typedef enum {
    ///Error not yet initialised.
    PPOPaymentErrorNotInitialised,
    
    ///Represents an unexpected error.
    PPOPaymentErrorUnexpected,
    
    ///An invalid parameter was supplied in your payment.
    PPOPaymentValidationError,
    
    ///The supplied bearer token has expired.
    PPOPaymentErrorClientTokenExpired,
    
    ///The supplied bearer token is invalid.
    PPOPaymentErrorClientTokenInvalid,
    
    ///The supplied token does not have sufficient permissions to access the specified feature.
    PPOPaymentErrorUnauthorisedRequest,
    
    ///The transaction was successfully submitted but did not complete three D secure validation.
    PPOPaymentErrorThreeDSecureTransactionProcessingFailed,
    
    ///An internal server error occurred at paypoint.
    PPOPaymentErrorServerFailure,
    
    ///The payment session timed out. This is the timeout that is passed into the payment manager.
    PPOPaymentErrorMasterSessionTimedOut,
    
    ///User cancelled 3D Secure.
    PPOPaymentErrorUserCancelledThreeDSecure,
    
    ///The payment is currently in flight.
    PPOPaymentErrorPaymentProcessing,
    
    ///The transaction was declined.
    PPOPaymentErrorTransactionDeclined,
    
    ///The presented API token was not valid the wrong type of authentication was used.
    PPOPaymentErrorAuthenticationFailed,
    
    ///The transaction or operation was not found.
    PPOPaymentErrorPaymentNotFound,
    
    ///A payment currently occupies the payment manager. Only one payment allowed per unit time.
    PPOPaymentErrorPaymentManagerOccupied
    
} PPOPaymentError;

/*!
   @discussion Errors relating to local validation.
   @typedef PPOLocalValidationError
   @constant PPOLocalValidationErrorNotInitialised Error not initialised yet.
   @constant PPOLocalValidationErrorClientTokenInvalid A client token has not been provided.
   @constant PPOLocalValidationErrorCardPanInvalid Pan card invalid.
   @constant PPOLocalValidationErrorCVVInvalid CVV card security code invalid.
   @constant PPOLocalValidationErrorCardExpiryDateExpired The date of the expirty for the current card has expired.
   @constant PPOLocalValidationErrorCardExpiryDateInvalid Card expiry date is invalid.
   @constant PPOLocalValidationErrorCurrencyInvalid Specified currency is invalid.
   @constant PPOLocalValidationErrorPaymentAmountInvalid The specified amount is invalid.
   @constant PPOLocalValidationErrorInstallationIDInvalid The provided installation ID is invalid.
   @constant PPOLocalValidationErrorSuppliedBaseURLInvalid The base URL configured within the payment manager is invalid.
   @constant PPOLocalValidationErrorCredentialsNotFound Credentials have not been set in the payment manager.
 */
typedef enum {
    
    ///Error not initialised yet.
    PPOLocalValidationErrorNotInitialised,
    
    ///A client token has not been provided.
    PPOLocalValidationErrorClientTokenInvalid,
    
    ///Pan card invalid.
    PPOLocalValidationErrorCardPanInvalid,
    
    ///CVV card security code invalid.
    PPOLocalValidationErrorCVVInvalid,
    
    ///The date of the expirty for the current card has expired.
    PPOLocalValidationErrorCardExpiryDateExpired,
    
    ///Card expiry date is invalid.
    PPOLocalValidationErrorCardExpiryDateInvalid,
    
    ///Specified currency is invalid.
    PPOLocalValidationErrorCurrencyInvalid,
    
    ///The specified amount is invalid.
    PPOLocalValidationErrorPaymentAmountInvalid,
    
    ///The provided installation ID is invalid.
    PPOLocalValidationErrorInstallationIDInvalid,
    
    ///The base URL configured within the payment manager is invalid.
    PPOLocalValidationErrorSuppliedBaseURLInvalid,
    
    ///Credentials have not been set in the payment manager.
    PPOLocalValidationErrorCredentialsNotFound,
    
} PPOLocalValidationError;
