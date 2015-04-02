//
//  LaunchViewController.h
//  Paypoint
//
//  Created by Robert Nash on 23/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <PaypointSDK/PaypointSDK.h>

@interface LaunchViewController : UIViewController <PPOPaymentControllerProtocol>
@property (weak, nonatomic) IBOutlet UIButton *payButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@end
