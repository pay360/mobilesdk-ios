//
//  NetworkManager.h
//  Paypoint
//
//  Created by Robert Nash on 08/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PaypointSDK/PPOCredentials.h>
#import "Reachability.h"

#define INSTALLATION_ID @"5300129"

@interface NetworkManager : NSObject

+(void)getCredentialsWithCompletion:(void(^)(PPOCredentials *credentials, NSURLResponse *response, NSError *error))completion;

@end
