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

+(NSError *)parsePaypointReasonCode:(NSInteger)reasonCode;

+(NSError*)buildErrorForPrivateError:(PPOPrivateError)code;

+(NSError*)buildErrorForPaymentError:(PPOPaymentError)code;

+(NSError*)buildErrorForValidationError:(PPOLocalValidationError)code;

//+(BOOL)safeToRetryPaymentWithoutRiskOfDuplication:(NSError*)error;

@end
