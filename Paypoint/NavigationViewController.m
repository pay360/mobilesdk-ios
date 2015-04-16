//
//  NavigationViewController.m
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "NavigationViewController.h"
#import "ColourManager.h"

@implementation NavigationViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    UIColor *blue = [ColourManager ppBlue];
    
    UIColor *white = [UIColor whiteColor];
    self.navigationBar.translucent = NO;
    self.navigationBar.tintColor = white;
    self.navigationBar.barTintColor = blue;
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: white};
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
