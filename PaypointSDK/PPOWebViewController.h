//
//  PPOWebViewController.h
//  Paypoint
//
//  Created by Robert Nash on 26/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "ThreeDSecureControllerProtocol.h"
#import "ThreeDSecureProtocol.h"

@interface PPOWebViewController : UIViewController <ThreeDSecureControllerProtocol>
@property (nonatomic, strong) id <ThreeDSecureProtocol> delegate; //Holding strongly here
@property (nonatomic, strong) PPORedirect *redirect;

-(instancetype)initWithRedirect:(PPORedirect*)redirect
                   withDelegate:(id<ThreeDSecureProtocol>)delegate;

@end
