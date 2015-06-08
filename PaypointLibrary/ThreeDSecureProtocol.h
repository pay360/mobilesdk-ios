//
//  ThreeDSecureProtocol.h
//  Paypoint
//
//  Created by Robert Nash on 08/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ThreeDSecureProtocol <NSObject>
-(void)threeDSecureController:(UIViewController*)controller completedWithPaRes:(NSString*)paRes;
-(void)webViewControllerUserCancelled:(UIViewController*)controller;
-(void)threeDSecureController:(UIViewController*)controller failedWithError:(NSError*)error;
-(void)threeDSecureControllerSessionTimeoutExpired:(UIViewController*)controller;
-(void)threeDSecureControllerDelayShowTimeoutExpired:(UIViewController*)controller;
@end
