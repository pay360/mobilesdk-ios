//
//  PPODeviceInfo.m
//  Paypoint
//
//  Created by Robert Nash on 18/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPODeviceInfo.h"
#import "PPOSDKConstants.h"

@interface PPODeviceInfo ()
@property (nonatomic, copy) NSString *uniqueIdentifier;
@end

@implementation PPODeviceInfo

-(NSString *)uniqueIdentifier {
    if (_uniqueIdentifier == nil) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *value = [userDefaults valueForKey:PPO_UNIQUE_IDENTIFIER];
        if (value && [value isKindOfClass:[NSString class]] && value.length > 0) {
            _uniqueIdentifier = value;
        } else {
            value = [NSUUID UUID].UUIDString;
            [userDefaults setValue:value forKey:PPO_UNIQUE_IDENTIFIER];
            _uniqueIdentifier = value;
        }
    }
    return _uniqueIdentifier;
}

-(NSDictionary*)jsonObjectRepresentation {
    id uniqueIdentifier = (self.uniqueIdentifier) ?: [NSNull null];
    
    return @{
             @"sdkInstallId": uniqueIdentifier
             };
}

@end
