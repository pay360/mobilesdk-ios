//
//  PPOOutcomeManager.m
//  Paypoint
//
//  Created by Robert Nash on 14/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOOutcomeManager.h"
#import "PPOErrorManager.h"

@implementation PPOOutcomeManager

+(PPOOutcome*)handleResponse:(NSData*)responseData withError:(NSError*)error {
        
    NSError *parsingError;
    id json;
    
    if (responseData) {
        json = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&parsingError];
    }
    
    if (parsingError) {
        
        NSString *errorDomain = PPOPaypointSDKErrorDomain;
        PPOErrorCode code = PPOErrorServerFailure;
        NSDictionary *userInfo = @{
                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"JSON received from Paypoint is Invalid", @"Parsing error message")
                                   };
        
        return [[PPOOutcome alloc] initWithData:json
                                      withError:[NSError errorWithDomain:errorDomain code:code userInfo:userInfo]
                ];
        
    } else {
        
        return [[PPOOutcome alloc] initWithData:json withError:error];
        
    }
}

@end
