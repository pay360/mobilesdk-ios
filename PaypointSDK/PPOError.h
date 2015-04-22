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
PPOSDK_EXTERN NSString *const PPOPaypointSDKErrorDomain;

/*!
 @typedef NS_ENUM (NSUInteger, PPOErrorCode)
 @abstract Error codes returned by the Paypoint SDK in NSError.
 
 @discussion
 These are valid only in the scope of PaypointSDKDomain.
 */
typedef NS_ENUM(NSInteger, PPOErrorCode) {
    
    /*! Error not initialised yet. */
    PPOErrorNotInitialised = -2,
    
    /*! Represents an unknown error.*/
    PPOErrorUnknown = -1,
    
    /*! Request was not correctly formed*/
    PPOErrorBadRequest,
    
    /* The presented API token was not valid, or the wrong type of authentication was used */
    PPOErrorAuthenticationFailed,
    
    /* Token Expired */
    PPOErrorClientTokenExpired,
    
    /* A client token has not been provided.*/
    PPOErrorClientTokenInvalid,
    
    /* The supplied token does not have sufficient permissions to you access the specified feature */
    PPOErrorUnauthorisedRequest,
    
    /* The transaction was successfully submitted but failed to be processed correctly. */
    PPOErrorTransactionProcessingFailed,
    
    /* An internal server error occurred at paypoint */
    PPOErrorServerFailure,
    
    /* Luhn check failed */
    PPOErrorLuhnCheckFailed,
    
    /* Pan card length invalid */
    PPOErrorCardPanLengthInvalid,
    
    /* CVV card security code invalid */
    PPOErrorCVVInvalid,
    
    /* Card expiry date is invalid */
    PPOErrorCardExpiryDateInvalid,
    
    /* Specified currency is invalid */
    PPOErrorCurrencyInvalid,
    
    /* The specified amount is invalid */
    PPOErrorPaymentAmountInvalid,
    
    /* The provided installation ID is invalid*/
    PPOErrorInstallationIDInvalid,
    
    /* The base URL configured within the payment manager, is invalid*/
    PPOErrorSuppliedBaseURLInvalid,
    
    /* Credentials have not been set in the payment manager*/
    PPOErrorCredentialsNotFound
    
};