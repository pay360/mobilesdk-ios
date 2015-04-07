//
//  PPOCredentials.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOCredentials.h"

@interface PPOCredentials ()
@property (nonatomic, strong, readwrite) NSString *installationID;
@property (nonatomic, strong, readwrite) NSString *token;
@end

@implementation PPOCredentials

-(instancetype)initWithID:(NSString*)installationID withToken:(NSString*)token {
    self = [super init];
    if (self) {
        _installationID = installationID;
        _token = token;
    }
    return self;
}

@end
