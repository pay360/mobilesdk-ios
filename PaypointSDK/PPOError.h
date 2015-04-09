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
PPOSDK_EXTERN NSString *const PaypointSDKDomain;

/*!
 @typedef NS_ENUM (NSUInteger, PPOErrorCode)
 @abstract Error codes returned by the Paypoint SDK in NSError.
 
 @discussion
 These are valid only in the scope of PaypointSDKDomain.
 */
typedef NS_ENUM(NSInteger, PPOErrorCode) {
    /*! Represents an unknown error.*/
    PPOErrorUnknown = -1,
    
    /*! Request was not correctly formed*/
    PPOErrorBadRequest,
    
    /* The presented API token was not valid, or the wrong type of authentication was used */
    PPOErrorAuthenticationFailed,
    
    /* Token Expired */
    PPOErrorClientTokenExpired,
    
    /* The token was valid, but does not grant you access to use the specified feature */
    PPOErrorUnauthorisedRequest,
    
    /* The transaction was successfully submitted but failed to be processed correctly. */
    PPOErrorTransactionProcessingFailed,
    
    /* An internal server error occurred at paypoint */
    PPOErrorServerFailure,
    
    /*  */
    PPOErrorLuhnCheckFailed
};