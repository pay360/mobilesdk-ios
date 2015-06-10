//
//  PPOError.m
//  Paypoint
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOSDKMacros.h"

/*!
 The NSError domain of all errors returned by the Paypoint SDK.
 */
PPOSDK_EXTERN NSString *const PPOPaymentErrorDomain;
PPOSDK_EXTERN NSString *const PPOLocalValidationErrorDomain;

/*!
 @typedef NS_ENUM (NSUInteger, PPOPaymentError)
 @abstract Error codes returned by the Paypoint SDK in NSError.
 
 @discussion
 Valid only in the scope of PPOPaymentErrorDomain.
 */
typedef NS_ENUM(NSInteger, PPOPaymentError) {
    
    /*! Error not initialised yet. */
    PPOPaymentErrorNotInitialised = -2,
    
    /*! Represents an unknown error. */
    PPOPaymentErrorUnexpected = -1,
    
    /* The supplied bearer token has expired. */
    PPOPaymentErrorClientTokenExpired,
    
    /* The supplied bearer token is invalid. */
    PPOPaymentErrorClientTokenInvalid,
    
    /* The supplied token does not have sufficient permissions to access the specified feature. */
    PPOPaymentErrorUnauthorisedRequest,
    
    /* The transaction was successfully submitted but did not complete three D secure validation. */
    PPOPaymentErrorThreeDSecureTransactionProcessingFailed,
    
    /* An internal server error occurred at paypoint */
    PPOPaymentErrorServerFailure,
    
    /* The payment session timed out. This is the timeout that is passed into the payment manager. */
    PPOPaymentErrorMasterSessionTimedOut,
    
    /* User cancelled 3D Secure */
    PPOPaymentErrorUserCancelledThreeDSecure,
    
    /* The payment is currently on hold awaiting Three D Secure to complete*/
    PPOPaymentErrorPaymentSuspendedForThreeDSecure,
    
    /* The payment is currently in flight */
    PPOPaymentErrorPaymentProcessing,
    
    /* The transaction was declined */
    PPOPaymentErrorTransactionDeclined,
    
    /* The presented API token was not valid, or the wrong type of authentication was used */
    PPOPaymentErrorAuthenticationFailed,
    
    /* The transaction or operation was not found */
    PPOPaymentErrorPaymentNotFound,
    
    /* A payment currently occupies the payment manager. Only one payment allowed per unit time.*/
    PPOPaymentErrorPaymentManagerOccupied
    
};

/*!
 @typedef NS_ENUM (NSUInteger, PPOLocalValidationError)
 @abstract Error codes returned by the Paypoint SDK during a payment.
 
 @discussion
 Valid only in the scope of PPOLocalValidationError.
 */
typedef NS_ENUM(NSInteger, PPOLocalValidationError) {
    
    /*! Error not initialised yet. */
    PPOLocalValidationErrorNotInitialised = -1,
    
    /* A client token has not been provided.*/
    PPOLocalValidationErrorClientTokenInvalid,
    
    /* Pan card invalid */
    PPOLocalValidationErrorCardPanInvalid,
    
    /* CVV card security code invalid */
    PPOLocalValidationErrorCVVInvalid,
    
    /* The date of the expirty for the current card has expired*/
    PPOLocalValidationErrorCardExpiryDateExpired,
    
    /* Card expiry date is invalid. */
    PPOLocalValidationErrorCardExpiryDateInvalid,
    
    /* Specified currency is invalid. */
    PPOLocalValidationErrorCurrencyInvalid,
    
    /* The specified amount is invalid */
    PPOLocalValidationErrorPaymentAmountInvalid,
    
    /* The provided installation ID is invalid*/
    PPOLocalValidationErrorInstallationIDInvalid,
    
    /* The base URL configured within the payment manager, is invalid*/
    PPOLocalValidationErrorSuppliedBaseURLInvalid,
    
    /* Credentials have not been set in the payment manager*/
    PPOLocalValidationErrorCredentialsNotFound,
    
};
