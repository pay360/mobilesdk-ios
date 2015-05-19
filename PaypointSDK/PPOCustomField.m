//
//  PPOCustomField.m
//  Paypoint
//
//  Created by Robert Nash on 19/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOCustomField.h"
#import "PPOSDKConstants.h"

@implementation PPOCustomField

-(NSDictionary*)jsonObjectRepresentation {
    
    NSMutableDictionary *mutableObject = [@{} mutableCopy];
    
    if (self.name) {
        id name = ([self cleanString:self.name]) ?: [NSNull null];
        [mutableObject setValue:name forKey:CUSTOM_FIELD_NAME];
    }
    
    if (self.value) {
        id value = ([self cleanString:self.value]) ?: [NSNull null];
        [mutableObject setValue:value forKey:CUSTOM_FIELD_VALUE];
    }
    
    if (self.isTransient) {
        [mutableObject setValue:self.isTransient forKey:CUSTOM_FIELD_TRANSIENT];
    }
    
    return [mutableObject copy];
}

-(NSString*)cleanString:(NSString*)string {
    return [string stringByReplacingOccurrencesOfString:@" " withString:@""];
}

-(instancetype)initWithData:(NSDictionary *)data {
    self = [super init];
    if (self) {
        id value;
        value = [data objectForKey:CUSTOM_FIELD_NAME];
        if ([value isKindOfClass:[NSString class]]) {
            self.name = value;
        }
        value = [data objectForKey:CUSTOM_FIELD_VALUE];
        if ([value isKindOfClass:[NSString class]]) {
            self.value = value;
        }
        value = [data objectForKey:CUSTOM_FIELD_TRANSIENT];
        if ([value isKindOfClass:[NSNumber class]]) {
            self.isTransient = value;
        }
    }
    return self;
}

@end
