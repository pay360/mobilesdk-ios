//
//  SubmitFormViewController.m
//  Paypoint
//
//  Created by Robert Nash on 08/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "SubmitFormViewController.h"
#import "Reachability.h"
#import <PaypointSDK/PPOPaymentManager.h>

#define INSTALLATION_ID @"5300129"

@interface SubmitFormViewController ()
@property (nonatomic, strong) PPOPaymentManager *paymentManager;
@end

@implementation SubmitFormViewController

#pragma mark - Lazy Instantiation

-(PPOPaymentManager *)paymentManager {
    if (_paymentManager == nil) {
        _paymentManager = [[PPOPaymentManager alloc] initWithCredentials:[self buildCredentials:@"VALID_TOKEN"]];
    }
    return _paymentManager;
}

-(PPOCredentials*)buildCredentials:(NSString*)token {
    return [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:token];
}

#pragma mark - Actions

-(IBAction)payNowButtonPressed:(UIButton *)sender {
    
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        [self showAlertWithMessage:@"There is no internet connection"];
    } else {
        [self makePaymentWithDetails:self.details];
    }
    
}

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

#pragma mark - Payment

-(void)makePaymentWithDetails:(FormDetails*)details {
    
    PPOTransaction *transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                                withAmount:@100
                                                           withDescription:@"A description"
                                                     withMerchantReference:@"mer_txn_1234556"
                                                                isDeferred:NO];
    
    PPOCreditCard *card = [[PPOCreditCard alloc] initWithPan:details.cardNumber
                                                    withCode:details.cvv
                                                  withExpiry:details.expiry
                                                    withName:@"John Smith"];
    
    PPOBillingAddress *address = [[PPOBillingAddress alloc] initWithFirstLine:nil
                                                               withSecondLine:nil
                                                                withThirdLine:nil
                                                               withFourthLine:nil
                                                                     withCity:nil
                                                                   withRegion:nil
                                                                 withPostcode:nil
                                                              withCountryCode:nil];
    
    [self.paymentManager startTransaction:transaction withCard:card forAddress:address completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSString *message = [self parseOutcome:data];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertWithMessage:message];
        });
        
    }];
    
}

#pragma - Payment Response Handling

- (NSString *)parseOutcome:(NSData *)data {
    NSString *message = @"Unknown outcome";
    
    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    id outcome = [json objectForKey:@"outcome"];
    if ([outcome isKindOfClass:[NSDictionary class]]) {
        id m = [outcome objectForKey:@"reasonMessage"];
        if ([m isKindOfClass:[NSString class]]) {
            message = m;
        }
    }
    return message;
}

-(void)showAlertWithMessage:(NSString*)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Outcome" message:message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
    [alertView show];
}

@end
