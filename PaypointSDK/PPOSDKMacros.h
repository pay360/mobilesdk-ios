//
//  PPOSDKMacros.m
//  Paypoint
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef __cplusplus
#define PPOSDK_EXTERN extern "C" __attribute__((visibility ("default")))
#else
#define PPOSDK_EXTERN extern __attribute__((visibility ("default")))
#endif

#define PPOSDK_STATIC_INLINE static inline
