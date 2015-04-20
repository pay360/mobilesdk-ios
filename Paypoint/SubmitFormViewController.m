//
//  SubmitFormViewController.m
//  Paypoint
//
//  Created by Robert Nash on 08/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "SubmitFormViewController.h"
#import "MerchantServer.h"
#import "EnvironmentManager.h"
#import "OutcomeViewController.h"

@interface SubmitFormViewController ()
@property (nonatomic, strong) PPOPaymentManager *paymentManager;
@end

@implementation SubmitFormViewController

-(void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.amountLabel.text = @"£100";
    
    PPOEnvironment currentEnvironment = [EnvironmentManager currentEnvironment];
    
    NSURL *baseURL = [PPOPaymentBaseURLManager baseURLForEnvironment:currentEnvironment];
    
    self.paymentManager = [[PPOPaymentManager alloc] initWithBaseURL:baseURL];
}

#pragma mark - Actions

-(IBAction)payNowButtonPressed:(UIButton *)sender {
    
    BOOL noNetwork = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable;
    
    if (noNetwork) {
        
        [self showAlertWithMessage:@"There is no internet connection"];
        
    } else if (self.animationState == LOADING_ANIMATION_STATE_ENDED) {
        
        [self attemptPayment:[self buildPaymentExample]];
        
    }
    
}

-(PPOPayment*)buildPaymentExample {
    
    PPOBillingAddress *address = [[PPOBillingAddress alloc] initWithFirstLine:nil
                                                               withSecondLine:nil
                                                                withThirdLine:nil
                                                               withFourthLine:nil
                                                                     withCity:nil
                                                                   withRegion:nil
                                                                 withPostcode:nil
                                                              withCountryCode:nil];
    
    PPOTransaction *transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                                withAmount:@100
                                                           withDescription:@"A description"
                                                     withMerchantReference:[NSString stringWithFormat:@"mer_%.0f", [[NSDate date] timeIntervalSince1970]]
                                                                isDeferred:NO];
    
    
    PPOCreditCard *card = [[PPOCreditCard alloc] initWithPan:self.form.cardNumber
                                        withSecurityCodeCode:self.form.cvv
                                                  withExpiry:self.form.expiry
                                          withCardholderName:@"Dai Jones"];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:transaction
                                                         withCard:card
                                               withBillingAddress:address];
    
    return payment;
}

-(void)attemptPayment:(PPOPayment*)payment {
    
    NSError *invalid = [self.paymentManager validatePayment:payment];
    
    if (invalid) {
        [self handleError:invalid];
        return;
    }
    
    [self beginAnimation];
    
    __weak typeof (self) weakSelf = self;
    
    [MerchantServer getCredentialsWithCompletion:^(PPOCredentials *credentials, NSError *retrievalError) {
        
        if (retrievalError) {
            [self handleError:retrievalError];
            return;
        }
        
        [weakSelf attemptPayment:payment withCredentials:credentials];
        
    }];
    
}

-(void)attemptPayment:(PPOPayment*)payment withCredentials:(PPOCredentials*)credentials {
    
    NSError *invalidCredentials = [self.paymentManager validateCredentials:credentials];
    
    if (invalidCredentials) {
        [self handleError:invalidCredentials];
        return;
    }
    
    __weak typeof (self) weakSelf = self;
    
    [self.paymentManager makePayment:payment
                     withCredentials:credentials
                         withTimeOut:60.0f
                      withCompletion:^(PPOOutcome *outcome, NSError *paymentFailure) {
                          
                          if (paymentFailure) {
                              [weakSelf handleError:paymentFailure];
                          } else {
                              [weakSelf endAnimationWithCompletion:^{
                                  [weakSelf performSegueWithIdentifier:@"OutcomeViewControllerSegueID" sender:outcome];
                              }];
                          }
                      }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"OutcomeViewControllerSegueID"] && [sender isKindOfClass:[PPOOutcome class]]) {
        PPOOutcome *outcome = (PPOOutcome*)sender;
        OutcomeViewController *controller = segue.destinationViewController;
        controller.outcome = outcome;
    }
}

-(void)handleError:(NSError*)error {
    
    NSString *message;
    
    if (error && error.domain == PPOPaypointSDKErrorDomain) {
        
        PPOErrorCode code = error.code;
        
        switch (code) {
            case PPOErrorNotInitialised: message = @"Error Code: PPOErrorNotInitialised"; break;
            case PPOErrorBadRequest: message = @"Error Code: PPOErrorBadRequest"; break;
            case PPOErrorAuthenticationFailed: message = @"Error Code: PPOErrorAuthenticationFailed"; break;
            case PPOErrorClientTokenExpired: message = @"Error Code: PPOErrorClientTokenExpired"; break;
            case PPOErrorUnauthorisedRequest: message = @"Error Code: PPOErrorUnauthorisedRequest"; break;
            case PPOErrorTransactionProcessingFailed: message = @"Error Code: PPOErrorTransactionProcessingFailed"; break;
            case PPOErrorServerFailure: message = @"Error Code: PPOErrorServerFailure"; break;
            case PPOErrorLuhnCheckFailed: message = @"Error Code: PPOErrorLuhnCheckFailed"; break;
            case PPOErrorCardExpiryDateInvalid: message = @"Error Code: PPOErrorCardExpiryDateInvalid"; break;
            case PPOErrorCardPanLengthInvalid: message = @"Error Code: PPOErrorCardPanLengthInvalid"; break;
            case PPOErrorCVVInvalid: message = @"Error Code: PPOErrorCVVInvalid"; break;
            case PPOErrorCurrencyInvalid: message = @"Error Code: PPOErrorCurrencyInvalid"; break;
            case PPOErrorPaymentAmountInvalid: message = @"Error Code: PPOErrorPaymentAmountInvalid"; break;
            case PPOErrorInstallationIDInvalid: message = @"Error Code: PPOErrorInstallationIDInvalid"; break;
            case PPOErrorSuppliedBaseURLInvalid: message = @"Error Code: PPOErrorSuppliedBaseURLInvalid"; break;
            case PPOErrorCredentialsNotFound: message = @"Error Code: PPOErrorCredentialsNotFound"; break;
            case PPOErrorUnknown: message = @"Error Code: PPOErrorUnknown"; break;
        }
        
    } else if ([self noNetwork:error]) {
        message = @"Something went wrong with the Network. There may have been a response timeout. Please check you are connected to the internet.";
    } else {
        message = [error.userInfo objectForKey:NSLocalizedFailureReasonErrorKey];
    }
    
    if (message) {
        
        [self endAnimationWithCompletion:^{
            [self showAlertWithMessage:message];
        }];
        
    }
    
}

@end
