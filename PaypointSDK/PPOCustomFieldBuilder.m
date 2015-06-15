//
//  PPOCustomFieldBuilder.m
//  PayPointPayments
//
//  Created by Robert Nash on 15/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOCustomFieldBuilder.h"
#import "PPOSDKConstants.h"

@implementation PPOCustomFieldBuilder

+(PPOCustomField *)customFieldWithData:(NSDictionary *)data {
    
    PPOCustomField *customField = [PPOCustomField new];
    
    id value;
    value = [data objectForKey:CUSTOM_FIELD_NAME];
    if ([value isKindOfClass:[NSString class]]) {
        customField.name = value;
    }
    value = [data objectForKey:CUSTOM_FIELD_VALUE];
    if ([value isKindOfClass:[NSString class]]) {
        customField.value = value;
    }
    value = [data objectForKey:CUSTOM_FIELD_TRANSIENT];
    if ([value isKindOfClass:[NSNumber class]]) {
        customField.isTransient = value;
    }
    
    return customField;
}

@end
