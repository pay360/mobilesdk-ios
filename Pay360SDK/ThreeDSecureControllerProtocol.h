//
//  ThreeDSecureControllerProtocol.h
//  Pay360
//
//  Created by Robert Nash on 08/06/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import "PPORedirect.h"

@protocol ThreeDSecureControllerProtocol <NSObject>

@property (nonatomic, strong) PPORedirect *redirect;

//Uniqued the names with prefix 'root', to avoid synthesis warning.
@property (nonatomic, strong) UINavigationController *rootNavigationController;
@property (nonatomic, strong) UIView *rootView;

@end