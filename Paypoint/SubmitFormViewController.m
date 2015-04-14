//
//  SubmitFormViewController.m
//  Paypoint
//
//  Created by Robert Nash on 08/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "SubmitFormViewController.h"
#import "NetworkManager.h"

#import <PaypointSDK/PaypointSDK.h>

@interface SubmitFormViewController ()
@property (nonatomic, strong) PPOPaymentManager *paymentManager;
@end

@implementation SubmitFormViewController

#pragma mark - Lazy Instantiation

-(PPOPaymentManager *)paymentManager {
    if (_paymentManager == nil) {
        _paymentManager = [[PPOPaymentManager alloc] initForEnvironment:[self currentEnvironment]];
    }
    return _paymentManager;
}

-(PPOEnvironment)currentEnvironment {
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    NSString *value = [environment objectForKey:@"ENVIRONMENT"];
    return value.integerValue;
}

#pragma mark - Actions

-(IBAction)textFieldEditingChanged:(UITextField *)textField {
    
    switch (textField.tag) {
        case TEXT_FIELD_TYPE_CARD_NUMBER:
            self.details.cardNumber = textField.text;
            break;
        case TEXT_FIELD_TYPE_CVV:
            self.details.cvv = textField.text;
            break;
        default:
            break;
    }
}

-(IBAction)payNowButtonPressed:(UIButton *)sender {
    
    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        
        [self showAlertWithMessage:@"There is no internet connection"];
        
    } else {
        
        PPOTransaction *transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                                    withAmount:@100
                                                               withDescription:@"A description"
                                                         withMerchantReference:@"mer_txn_1234556"
                                                                    isDeferred:NO];
        
        PPOCreditCard *card = [[PPOCreditCard alloc] initWithPan:self.details.cardNumber
                                                        withCode:self.details.cvv
                                                      withExpiry:self.details.expiry
                                                        withName:@"John Smith"];
        
        PPOBillingAddress *address = [[PPOBillingAddress alloc] initWithFirstLine:nil
                                                                   withSecondLine:nil
                                                                    withThirdLine:nil
                                                                   withFourthLine:nil
                                                                         withCity:nil
                                                                       withRegion:nil
                                                                     withPostcode:nil
                                                                  withCountryCode:nil];
        
        __weak typeof (self) weakSelf = self;
        
        [NetworkManager getCredentialsWithCompletion:^(PPOCredentials *credentials, NSURLResponse *response, NSError *error) {
            
            if ([weakSelf handleError:error]) return;
            
            [weakSelf.paymentManager setCredentials:credentials];
            
            [weakSelf.paymentManager makePaymentWithTransaction:transaction
                                                        forCard:card
                                             withBillingAddress:address
                                                    withTimeOut:5.0f
                                                 withCompletion:^(PPOOutcome *outcome) {
                                                     
                                                     [weakSelf handleOutcome:outcome];
                                                     
                                                 }];
            
        }];
        
    }
    
}

-(void)handleOutcome:(PPOOutcome*)outcome {
    if (outcome.error) {
        [self handleError:outcome.error];
    } else {
        [self showAlertWithMessage:@"Payment Authorised"];
    }
}

-(BOOL)handleError:(NSError*)error {
    
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
            case PPOErrorUnknown: message = @"Error Code: PPOErrorUnknown"; break;
        }
        
    } else if ([self noNetwork:error]) {
        message = @"Something went wrong with the Network. There may have been a response timeout. Please check you are connected to the internet.";
    } else {
        message = [error.userInfo objectForKey:NSLocalizedFailureReasonErrorKey];
    }
    
    if (message) {
        [self showAlertWithMessage:message];
        return YES;
    }
    
    return NO;
}

#pragma mark - Typical Response Error Handling

-(BOOL)noNetwork:(NSError*)error {
    return [[self noNetworkConnectionErrorCodes] containsObject:@(error.code)];
}

-(NSArray*)noNetworkConnectionErrorCodes {
    int codes[] = {
        kCFURLErrorTimedOut,
        kCFURLErrorCannotConnectToHost,
        kCFURLErrorNetworkConnectionLost,
        kCFURLErrorDNSLookupFailed,
        kCFURLErrorResourceUnavailable,
        kCFURLErrorNotConnectedToInternet,
        kCFURLErrorInternationalRoamingOff,
        kCFURLErrorCallIsActive,
        kCFURLErrorFileDoesNotExist,
        kCFURLErrorNoPermissionsToReadFile,
    };
    int size = sizeof(codes)/sizeof(int);
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i=0;i<size;++i){
        [array addObject:[NSNumber numberWithInt:codes[i]]];
    }
    return [array copy];
}

#pragma mark - Helpers

-(void)showAlertWithMessage:(NSString*)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Outcome" message:message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
    [alertView show];
}

@end
