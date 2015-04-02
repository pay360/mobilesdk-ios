//
//  LaunchViewController.m
//  Paypoint
//
//  Created by Robert Nash on 23/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "LaunchViewController.h"

@implementation LaunchViewController

- (IBAction)payButtonPresseded:(UIButton *)sender {
    [self presentViewController:[PPOPaymentController paymentFlowWithDelegate:self]
                       animated:YES
                     completion:nil];
}

#pragma mark - PaymentController Delegate

-(void)userCancelledCardFormEntry {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)userCompletedCardFormEntry:(NSString*)message {
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self showAlertWithMessage:message];
    }];
    
}

-(void)showAlertWithMessage:(NSString*)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Outcome" message:message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
    [alertView show];
}

@end
