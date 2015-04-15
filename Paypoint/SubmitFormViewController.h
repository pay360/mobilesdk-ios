//
//  SubmitFormViewController.h
//  Paypoint
//
//  Created by Robert Nash on 08/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "FormViewController.h"

#import <PaypointSDK/PaypointSDK.h>

@interface SubmitFormViewController : FormViewController

@property (nonatomic, strong) PPOPayment *payment;

@end
