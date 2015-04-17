//
//  OutcomeViewController.m
//  Paypoint
//
//  Created by Robert Nash on 17/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "OutcomeViewController.h"
#import "ColourManager.h"
#import "ButtonStyler.h"

#import <PaypointSDK/PPOOutcome.h>

@interface OutcomeViewController ()
@property (nonatomic, strong) IBOutlet UILabel *tickLabel;
@property (weak, nonatomic) IBOutlet UILabel *cardNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *merchantRefLabel;
@property (weak, nonatomic) IBOutlet UILabel *transactionIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UIButton *finishButton;
@end

@implementation OutcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Restart"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(restartButtonPressed:)];
    
    self.tickLabel.text = @"\uF00C";
    self.tickLabel.textColor = [ColourManager ppYellow];
    
    self.cardNumberLabel.text = (self.outcome.lastFour) ? [NSString stringWithFormat:@"**** **** **** %@", self.outcome.lastFour] : @"";
    self.merchantRefLabel.text = (self.outcome.merchantRef) ?: @"";
    self.transactionIDLabel.text = (self.outcome.identifier) ?: @"";
    self.amountLabel.text = (self.outcome.amount.stringValue) ? [NSString stringWithFormat:@"£%@.00", self.outcome.amount.stringValue] : @"";
    
    [ButtonStyler styleButton:self.finishButton];
}

- (void)restartButtonPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
