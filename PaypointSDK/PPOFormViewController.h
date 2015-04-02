//
//  PPOFormViewController.h
//  Paypoint
//
//  Created by Robert Nash on 23/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPOPaymentControllerProtocol.h"

@interface PPOFormViewController : UIViewController

-(instancetype)initWithDelegate:(id<PPOPaymentControllerProtocol>)delegate;

@end
