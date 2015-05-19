//
//  PPOCustomField.m
//  Paypoint
//
//  Created by Robert Nash on 19/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOCustomField.h"

@implementation PPOCustomField

-(NSDictionary*)jsonObjectRepresentation {
    
    NSMutableDictionary *mutableObject = [@{} mutableCopy];
    
    if (self.name) {
        id name = ([self cleanString:self.name]) ?: [NSNull null];
        [mutableObject setValue:name forKey:@"name"];
    }
    
    if (self.value) {
        id value = ([self cleanString:self.value]) ?: [NSNull null];
        [mutableObject setValue:value forKey:@"value"];
    }
    
    if (self.isTransient) {
        [mutableObject setValue:self.isTransient forKey:@"transient"];
    }
    
    return [mutableObject copy];
}

-(NSString*)cleanString:(NSString*)string {
    return [string stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
