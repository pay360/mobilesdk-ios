//
//  PPOErrorController.h
//  Paypoint
//
//  Created by Robert Nash on 25/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    PPO_PAYPOINT_ERROR_
} PPO_PAYPOINT_ERROR;

extern NSString *const PPOSDKErrorDomain;

@interface PPOErrorController : NSObject

@end
