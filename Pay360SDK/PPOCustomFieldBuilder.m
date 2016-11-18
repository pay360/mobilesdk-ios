//
//  PPOCustomFieldBuilder.m
//  Pay360Payments
//
//  Created by Robert Nash on 15/06/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import "PPOCustomFieldBuilder.h"
#import "PPOSDKConstants.h"

@implementation PPOCustomFieldBuilder

+(PPOCustomField *)customFieldWithData:(NSDictionary *)data {
    
    if (!data || ![data isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
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
