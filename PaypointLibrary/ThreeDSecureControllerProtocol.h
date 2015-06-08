//
//  ThreeDSecureControllerProtocol.h
//  Paypoint
//
//  Created by Robert Nash on 08/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPORedirect.h"

@protocol ThreeDSecureControllerProtocol <NSObject>

@property (nonatomic, strong) PPORedirect *redirect;

@end