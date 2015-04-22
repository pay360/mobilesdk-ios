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
        
        [self showAlertWithMessage:@"There is no internet connection" withCompletion:^(BOOL isFinished) {
            
        }];
        
    } else if (self.animationState == LOADING_ANIMATION_STATE_ENDED) {
        
        [self attemptPayment:[self buildPaymentExampleWithDetails:self.form]];
        
    }
    
}

-(PPOPayment*)buildPaymentExampleWithDetails:(FormDetails*)form {
    
    PPOBillingAddress *address = [[PPOBillingAddress alloc] initWithFirstLine:nil
                                                               withSecondLine:nil
                                                                withThirdLine:nil
                                                               withFourthLine:nil
                                                                     withCity:nil
                                                                   withRegion:nil
                                                                 withPostcode:nil
                                                              withCountryCode:nil];
    
    NSString *genericRef = [NSString stringWithFormat:@"mer_%.0f", [[NSDate date] timeIntervalSince1970]];
    
    PPOTransaction *transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                                withAmount:@100
                                                           withDescription:@"A description"
                                                     withMerchantReference:genericRef
                                                                isDeferred:NO];
    
    
    PPOCreditCard *card = [[PPOCreditCard alloc] initWithPan:form.cardNumber
                                        withSecurityCodeCode:form.cvv
                                                  withExpiry:form.expiry
                                          withCardholderName:@"Dai Jones"];
    
    return [[PPOPayment alloc] initWithTransaction:transaction
                                          withCard:card
                                withBillingAddress:address];
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
                              
                              __strong typeof(weakSelf) strongSelf = weakSelf;
                              
                              [weakSelf endAnimationWithCompletion:^{
                                  [strongSelf performSegueWithIdentifier:@"OutcomeViewControllerSegueID" sender:outcome];
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
    
    __weak typeof(self) weakSelf = self;
    
    if (error && error.domain == PPOPaypointSDKErrorDomain) {
        
        message = [error.userInfo objectForKey:NSLocalizedFailureReasonErrorKey];
        
        [self endAnimationWithCompletion:^{
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            [weakSelf showAlertWithMessage:message
                            withCompletion:^(BOOL isFinished) {
                                
                                PPOErrorCode code = error.code;
                                
                                UITextField *textField;
                                
                                switch (code) {
                                    case PPOErrorNotInitialised: break;
                                    case PPOErrorBadRequest: break;
                                    case PPOErrorAuthenticationFailed: break;
                                    case PPOErrorClientTokenExpired: break;
                                    case PPOErrorUnauthorisedRequest: break;
                                    case PPOErrorTransactionProcessingFailed: break;
                                    case PPOErrorServerFailure: break;
                                    case PPOErrorLuhnCheckFailed: textField = strongSelf.textFields[TEXT_FIELD_TYPE_CARD_NUMBER]; break;
                                    case PPOErrorCardExpiryDateInvalid: textField = strongSelf.textFields[TEXT_FIELD_TYPE_EXPIRY]; break;
                                    case PPOErrorClientTokenInvalid: break;
                                    case PPOErrorCardPanLengthInvalid: textField = strongSelf.textFields[TEXT_FIELD_TYPE_CARD_NUMBER]; break;
                                    case PPOErrorCVVInvalid: textField = strongSelf.textFields[TEXT_FIELD_TYPE_CVV]; break;
                                    case PPOErrorCurrencyInvalid: break;
                                    case PPOErrorPaymentAmountInvalid: break;
                                    case PPOErrorInstallationIDInvalid: break;
                                    case PPOErrorSuppliedBaseURLInvalid: break;
                                    case PPOErrorCredentialsNotFound: break;
                                    case PPOErrorUnknown: break;
                                }
                                
                                if (textField) {
                                    [textField.layer addAnimation:[strongSelf shakeAnimation] forKey:@"transform"];
                                }
                                
                            }];
        }];
        
    }
    else if ([self noNetwork:error]) {
        message = @"Something went wrong with the Network. There may have been a response timeout. Please check you are connected to the internet.";
        
        [self endAnimationWithCompletion:^{
            
            [weakSelf showAlertWithMessage:message
                            withCompletion:^(BOOL isFinished) {
                                
                            }];
        }];
    }
    
}

-(CAKeyframeAnimation*)shakeAnimation {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-10.0, 0.0, 0.0)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(10.0, 0.0, 0.0)]];
    animation.autoreverses = YES;
    animation.repeatCount = 2;
    animation.duration = 0.07;
    return animation;
}

@end
