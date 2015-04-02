//
//  PPONavigationViewController.m
//  Paypoint
//
//  Created by Robert Nash on 23/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPONavigationViewController.h"

@interface PPONavigationViewController ()

@end

@implementation PPONavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.navigationBar.translucent = NO;
    self.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0f green:23/255.0f blue:68/255.0f alpha:1];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
