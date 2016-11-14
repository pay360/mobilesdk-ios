//
//  ThreeDSecureProtocol.h
//  Pay360
//
//  Created by Robert Nash on 08/06/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import "ThreeDSecureControllerProtocol.h"

@protocol ThreeDSecureProtocol <NSObject>
-(void)threeDSecureController:(id<ThreeDSecureControllerProtocol>)controller acquiredPaRes:(NSString*)paRes;
-(void)threeDSecureControllerUserCancelled:(id<ThreeDSecureControllerProtocol>)controller;
-(void)threeDSecureController:(id<ThreeDSecureControllerProtocol>)controller failedWithError:(NSError*)error;
-(void)threeDSecureControllerSessionTimeoutExpired:(id<ThreeDSecureControllerProtocol>)controller;
-(void)threeDSecureControllerDelayShowTimeoutExpired:(id<ThreeDSecureControllerProtocol>)controller;
@end
