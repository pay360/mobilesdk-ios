//
//  ThreeDSecureProtocol.h
//  Paypoint
//
//  Created by Robert Nash on 08/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThreeDSecureControllerProtocol.h"

@protocol ThreeDSecureProtocol <NSObject>
-(void)threeDSecureController:(id<ThreeDSecureControllerProtocol>)controller completedWithPaRes:(NSString*)paRes;
-(void)threeDSecureControllerUserCancelled:(id<ThreeDSecureControllerProtocol>)controller;
-(void)threeDSecureController:(id<ThreeDSecureControllerProtocol>)controller failedWithError:(NSError*)error;
-(void)threeDSecureControllerSessionTimeoutExpired:(id<ThreeDSecureControllerProtocol>)controller;
-(void)threeDSecureControllerDelayShowTimeoutExpired:(id<ThreeDSecureControllerProtocol>)controller;
@end
