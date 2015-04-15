//
//  EndpointManager.h
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <PaypointSDK/PaypointSDK.h>

@interface EndpointManager : NSObject

+(NSURL*)baseURL:(PPOEnvironment)environment;

@end
