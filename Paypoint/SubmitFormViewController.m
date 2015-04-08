//
//  SubmitFormViewController.m
//  Paypoint
//
//  Created by Robert Nash on 08/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "SubmitFormViewController.h"
#import "Reachability.h"
#import "NetworkManager.h"

#import <PaypointSDK/PaypointSDK.h>

@interface SubmitFormViewController () <PPOPaymentManagerDelegate, PPOPaymentManagerDatasource>
@property (nonatomic, strong) PPOPaymentManager *paymentManager;
@end

@implementation SubmitFormViewController

#pragma mark - Lazy Instantiation

-(PPOPaymentManager *)paymentManager {
    if (_paymentManager == nil) {
        _paymentManager = [PPOPaymentManager new];
        _paymentManager.delegate = self;
        _paymentManager.datasource = self;
    }
    return _paymentManager;
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
    
    self.payNowButton.hidden = ![self.details isComplete];
    
}

-(IBAction)payNowButtonPressed:(UIButton *)sender {
    
    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        
        [self showAlertWithMessage:@"There is no internet connection"];
        
    } else {
        
        __weak typeof (self) weakSelf = self;
        
        [NetworkManager getCredentialsUsingCacheIfAvailable:YES withCompletion:^(PPOCredentials *credentials, NSURLResponse *response, NSError *error) {
            
            if ([weakSelf issuesFound:error withToken:credentials.token]) return;
            
            PPOTransaction *transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                                        withAmount:@100
                                                                   withDescription:@"A description"
                                                             withMerchantReference:@"mer_txn_1234556"
                                                                        isDeferred:NO];
            
            [weakSelf.paymentManager setCredentials:credentials];
            [weakSelf.paymentManager startTransaction:transaction];
            
        }];
        
    }
    
}

#pragma mark - PPOPaymentManagerDatasource

-(PPOCreditCard *)creditCard {
    return [[PPOCreditCard alloc] initWithPan:self.details.cardNumber
                                     withCode:self.details.cvv
                                   withExpiry:self.details.expiry
                                     withName:@"John Smith"];
}

-(PPOBillingAddress*)billingAddress {
    return [[PPOBillingAddress alloc] initWithFirstLine:nil
                                         withSecondLine:nil
                                          withThirdLine:nil
                                         withFourthLine:nil
                                               withCity:nil
                                             withRegion:nil
                                           withPostcode:nil
                                        withCountryCode:nil];
}

#pragma mark - PPOPaymentManagerDelegate

-(void)paymentSucceeded:(NSString *)feedback {
    [self showAlertWithMessage:feedback];
}

-(void)paymentFailed:(NSError *)error {
    [self showAlertWithMessage:error.localizedDescription];
}

#pragma mark - Typical Response Error Handling

-(BOOL)issuesFound:(NSError*)error withToken:(NSString*)token {
    
    BOOL errorFound = NO;
    
    if ([self noNetwork:error]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertWithMessage:@"Unable to fetch credentials. Please check you are connected to the internet."];
        });
        
        errorFound = YES;
    }
    
    if (!token || token.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertWithMessage:@"Invalid credentials"];
        });
        
        errorFound = YES;
    }
    
    return errorFound;
    
}

-(BOOL)noNetwork:(NSError*)error {
    return [[self noNetworkConnectionErrorCodes] containsObject:@(error.code)];
}

-(NSArray*)noNetworkConnectionErrorCodes {
    int codes[] = {
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
