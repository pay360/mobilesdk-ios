//
//  PPOCredentials.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOCredentials.h"

@implementation PPOCredentials

-(NSString *)installationID {
    if (_installationID == nil) {
        _installationID = @"5300065";
    }
    return _installationID;
}

@end
