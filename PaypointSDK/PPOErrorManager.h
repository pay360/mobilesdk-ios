//
//  PPOErrorManager.h
//  Pay360
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import "PPOError.h"
#import "PPOPrivateError.h"
#import "PPOOutcome.h"

@interface PPOErrorManager : NSObject

+(NSError*)parsePaypointReasonCode:(NSInteger)code withMessage:(NSString*)message;

+(NSError*)buildErrorForPrivateErrorCode:(PPOPrivateError)code withMessage:(NSString*)message;

+(NSError*)buildErrorForPaymentErrorCode:(PPOPaymentError)code withMessage:(NSString*)message;

+(NSError*)buildErrorForValidationErrorCode:(PPOLocalValidationError)code;

+(NSError*)buildCustomerFacingErrorFromError:(NSError*)error;

/*
 * This class is private, but this method is called by a class that is public.
 * It is only useful for the public call. The SDK shoudl only endevours to discover a
 * conclusion for a payment and should not retry a payment independently of an
 * explicit instruction to do so, by the implementing developer.
 */
+(BOOL)isSafeToRetryPaymentWithError:(NSError*)error;

@end
