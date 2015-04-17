//
//  WelcomeViewController.m
//  Paypoint
//
//  Created by Robert Nash on 16/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "WelcomeViewController.h"
#import "ColourManager.h"
#import "SubmitFormViewController.h"

@interface WelcomeViewController ()
@property (weak, nonatomic) IBOutlet UILabel *paypointLabel;
@property (weak, nonatomic) IBOutlet UIImageView *paypointLogo;
@property (weak, nonatomic) IBOutlet UIView *logoContainer;
@property (weak, nonatomic) IBOutlet UIView *splashView;
@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.paypointLabel.textColor = [ColourManager ppBlue];
    
}

-(UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.splashView) {
        [UIView animateWithDuration:.3 animations:^{
            self.splashView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.splashView removeFromSuperview];
            self.splashView = nil;
        }];
    }
}

@end
