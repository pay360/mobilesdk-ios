//
//  PPOOutcome.m
//  Paypoint
//
//  Created by Robert Nash on 10/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOOutcome.h"
#import "PPOError.h"

@interface PPOOutcome ()
@property (nonatomic, strong, readwrite) NSString *reasonMessage;
@property (nonatomic, strong, readwrite) NSNumber *reasonCode;
@property (nonatomic, strong, readwrite) NSString *status;
@end

@implementation PPOOutcome

-(NSNumber *)reasonCode {
    if (_reasonCode == nil) {
        _reasonCode = @(PPOErrorNotInitialised);
    }
    return _reasonCode;
}

-(instancetype)initWithData:(NSDictionary*)data {
    self = [super init];
    
    if (self) {
        [self parseOutcome:[data objectForKey:@"outcome"]];
    }
    
    return self;
}

-(void)parseOutcome:(NSDictionary*)outcome {
    id value;
    if ([outcome isKindOfClass:[NSDictionary class]]) {
        value = [outcome objectForKey:@"reasonCode"];
        if ([value isKindOfClass:[NSNumber class]]) {
            self.reasonCode = value;
        }
        value = [outcome objectForKey:@"reasonMessage"];
        if ([value isKindOfClass:[NSNumber class]]) {
            self.reasonMessage = value;
        }
    }
}

@end
