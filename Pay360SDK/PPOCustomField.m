//
//  PPOCustomField.m
//  Pay360
//
//  Created by Robert Nash on 19/05/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import "PPOCustomField.h"
#import "PPOSDKConstants.h"

@implementation PPOCustomField

-(NSDictionary*)jsonObjectRepresentation {
    
    NSMutableDictionary *mutableObject = [@{} mutableCopy];
    
    if (self.name) {
        id name = ([self cleanString:self.name]) ?: [NSNull null];
        [mutableObject setValue:name
                         forKey:CUSTOM_FIELD_NAME];
    }
    
    if (self.value) {
        id value = ([self cleanString:self.value]) ?: [NSNull null];
        [mutableObject setValue:value
                         forKey:CUSTOM_FIELD_VALUE];
    }
    
    id transient = (self.isTransient) ?: [NSNull null];
    
    NSNumber *isTransient = transient;
    
    if ([isTransient isKindOfClass:[NSNumber class]] && isTransient.integerValue > 1) {
        isTransient = @NO;
    }
    
    [mutableObject setValue:isTransient
                     forKey:CUSTOM_FIELD_TRANSIENT];
    
    return [mutableObject copy];
}

-(NSString*)cleanString:(NSString*)string {
    return [string stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
