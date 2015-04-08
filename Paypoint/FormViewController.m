//
//  FormViewController.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "FormViewController.h"
#import "TimeManager.h"
#import "FormDetails.h"
#import "Reachability.h"

#import <PaypointSDK/PPOPaymentManager.h>

typedef enum : NSUInteger {
    TEXT_FIELD_TYPE_CARD_NUMBER,
    TEXT_FIELD_TYPE_EXPIRY,
    TEXT_FIELD_TYPE_CVV
} TEXT_FIELD_TYPE;

@interface FormViewController () <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *titleLabels;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (weak, nonatomic) IBOutlet UIButton *payNowButton;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) NSArray *pickerViewSelections;
@property (nonatomic, strong) FormDetails *details;
@property (nonatomic, strong) TimeManager *timeController;
@property (nonatomic, strong) PPOPaymentManager *paymentManager;
@end

@implementation FormViewController

-(FormDetails *)details {
    if (_details == nil) {
        _details = [FormDetails new];
    }
    return _details;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *token = @"VALID_TOKEN";
    NSString *installationID = @"5300129";
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:installationID withToken:token];
    self.paymentManager = [[PPOPaymentManager alloc] initWithCredentials:credentials];
    
    self.title = @"Details";
    
    for (UITextField *textField in self.textFields) {
        textField.delegate = self;
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    [self.view addGestureRecognizer:tap];
}

-(TimeManager *)timeController {
    if (_timeController == nil) {
        _timeController = [TimeManager new];
    }
    return _timeController;
}

-(NSArray *)pickerViewSelections {
    if (_pickerViewSelections == nil) {
        _pickerViewSelections = [TimeManager expiryDatesFromDate:[NSDate date]];
    }
    return _pickerViewSelections;
}

-(UIPickerView *)pickerView {
    if (_pickerView == nil) {
        _pickerView = [[UIPickerView alloc] init];
        _pickerView.showsSelectionIndicator = YES;
        _pickerView.delegate = self;
        _pickerView.dataSource = self;
    }
    return _pickerView;
}

#pragma mark - Actions

-(void)doneButtonPressed:(UIBarButtonItem*)button {
    [self.view endEditing:YES];
    self.navigationItem.rightBarButtonItem = nil;
}

-(void)backgroundTapped:(UITapGestureRecognizer*)gesture {
    [self.view endEditing:YES];
    self.navigationItem.rightBarButtonItem = nil;
}

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

#pragma mark - UITextField Delegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    if (textField.tag == TEXT_FIELD_TYPE_EXPIRY) {
        textField.inputView = self.pickerView;
        NSInteger selected = [self.pickerView selectedRowInComponent:0];
        if (selected != -1 && selected >= 0 && selected < self.pickerViewSelections.count) {
            NSDate *selection = self.pickerViewSelections[selected];
            NSString *date = [self.timeController.cardExpiryDateFormatter stringFromDate:selection];
            textField.text = date;
            self.details.expiry = date;
        }
        self.payNowButton.hidden = ![self.details isComplete];
    }
    
    return YES;
}

-(BOOL)textFieldShouldClear:(UITextField *)textField {
    textField.text = nil;
    
    switch (textField.tag) {
        case TEXT_FIELD_TYPE_CARD_NUMBER:
            self.details.cardNumber = nil;
            break;
        case TEXT_FIELD_TYPE_EXPIRY:
            self.details.expiry = nil;
            break;
        case TEXT_FIELD_TYPE_CVV:
            self.details.cvv = nil;
            break;
    }
    
    self.payNowButton.hidden = ![self.details isComplete];
    
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    UITextField *nextTextField;
    
    switch (textField.tag) {
        case TEXT_FIELD_TYPE_CARD_NUMBER:
            nextTextField = self.textFields[TEXT_FIELD_TYPE_EXPIRY];
            break;
        case TEXT_FIELD_TYPE_EXPIRY:
            nextTextField = self.textFields[TEXT_FIELD_TYPE_CVV];
            break;
        case TEXT_FIELD_TYPE_CVV:
            [textField resignFirstResponder];
            break;
    }
    
    if (nextTextField) {
        [nextTextField becomeFirstResponder];
    }
    
    return YES;
}

#pragma mark - UIPickerView Datasource

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.pickerViewSelections.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSDate *date = self.pickerViewSelections[row];
    return [self.timeController.cardExpiryDateFormatter stringFromDate:date];
}

#pragma mark - UIPickerView Delegate

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSDate *date = self.pickerViewSelections[row];
    
    UITextField *textField = self.textFields[TEXT_FIELD_TYPE_EXPIRY];
    NSString *dateString = [self.timeController.cardExpiryDateFormatter stringFromDate:date];
    textField.text = dateString;
    self.details.expiry = dateString;
    
    self.payNowButton.hidden = ![self.details isComplete];
}

@end
