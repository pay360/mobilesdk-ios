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
    
    /* A supplied parameter was invalid. Please use our convenience validation functions before making a payment. */
    PPOPaymentErrorInvalidParameter,
    
    /* Token Expired. */
    PPOPaymentErrorClientTokenExpired,
    
    /* The supplied token does not have sufficient permissions to access the specified feature. */
    PPOPaymentErrorUnauthorisedRequest,
    
    /* The transaction was successfully submitted but failed to be processed correctly. */
    PPOPaymentErrorTransactionProcessingFailed,
    
    /* An internal server error occurred at paypoint */
    PPOPaymentErrorServerFailure,
    
    /* The payment session timed out. This is the timeout that is passed into the payment manager. */
    PPOPaymentErrorMasterSessionTimedOut,
    
    /* User cancelled 3D Secure */
    PPOErrorUserCancelled,
    
    /* The payment is currently in flight */
    PPOErrorPaymentProcessing,
    
    /* The transaction was declined */
    PPOErrorTransactionDeclined,
    
    /* The transaction or operation was not found */
    PPOErrorPaymentNotFound,
    
    /* A payment currently occupies the payment manager. Only one payment allowed per unit time.*/
    PPOErrorPaymentManagerOccupied
    
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
    PPOLocalValidationCurrencyInvalid,
    
    /* The specified amount is invalid */
    PPOLocalValidationErrorPaymentAmountInvalid,
    
    /* The provided installation ID is invalid*/
    PPOLocalValidationErrorInstallationIDInvalid,
    
    /* The base URL configured within the payment manager, is invalid*/
    PPOLocalValidationErrorSuppliedBaseURLInvalid,
    
    /* Credentials have not been set in the payment manager*/
    PPOLocalValidationErrorCredentialsNotFound,
    
};
