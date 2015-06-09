//
//  PPOErrorManager.h
//  Paypoint
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOError.h"
#import "PPOOutcome.h"
#import "PPOInternalError.h"

@interface PPOErrorManager : NSObject

+(NSError *)parsePaypointReasonCode:(NSInteger)code;

+(NSError*)buildErrorForPrivateErrorCode:(PPOPrivateError)code;

+(NSError*)buildErrorForPaymentErrorCode:(PPOPaymentError)code;

+(NSError*)buildErrorForValidationErrorCode:(PPOLocalValidationError)code;

//+(BOOL)safeToRetryPaymentWithoutRiskOfDuplication:(NSError*)error;

@end
