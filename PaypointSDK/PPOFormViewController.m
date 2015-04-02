//
//  PPOFormViewController.m
//  Paypoint
//
//  Created by Robert Nash on 23/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOFormViewController.h"
#import "PPOPaymentForm.h"
#import "PPOTimeController.h"
#import "PPOReachability.h"
#import "PPOPaymentController.h"
#import "PPOErrorController.h"
#import "PPOWebViewController.h"
#import "PPONavigationViewController.h"

#define PAYPOINT_SDK_BUNDLE_URL [[NSBundle bundleForClass:[self class]] URLForResource:@"PaypointSDKBundle" withExtension:@"bundle"]

typedef enum : NSUInteger {
    TEXT_FIELD_TYPE_CARD_NUMBER,
    TEXT_FIELD_TYPE_EXPIRY,
    TEXT_FIELD_TYPE_CVV
} TEXT_FIELD_TYPE;

@interface PPOFormViewController () <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, PPOWebViewControllerDelegate>
@property (nonatomic, weak) id <PPOPaymentControllerProtocol> delegate;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *titleLabels;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (weak, nonatomic) IBOutlet UIButton *payNowButton;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) NSArray *pickerViewSelections;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) PPOPaymentForm *details;
@property (nonatomic, strong) PPOTimeController *timeController;
@end

@implementation PPOFormViewController

-(instancetype)initWithDelegate:(id<PPOPaymentControllerProtocol>)delegate {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleWithURL:PAYPOINT_SDK_BUNDLE_URL]];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Details";
    
    self.logoImageView.image = [self paypointLogo];
    
    for (UITextField *textField in self.textFields) {
        textField.delegate = self;
    }
    
    id top = self.topLayoutGuide;
    UILabel *label = self.titleLabels.firstObject;
    NSDictionary *views = NSDictionaryOfVariableBindings(label, top);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[top]-20-[label]" options:0 metrics:nil views:views]];
    
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    [self.view addGestureRecognizer:tap];
}

-(PPOTimeController *)timeController {
    if (_timeController == nil) {
        _timeController = [PPOTimeController new];
    }
    return _timeController;
}

-(PPOPaymentForm *)details {
    if (_details == nil){
        _details = [PPOPaymentForm new];
    }
    return _details;
}

-(NSArray *)pickerViewSelections {
    if (_pickerViewSelections == nil) {
        _pickerViewSelections = [PPOTimeController expiryDatesFromDate:[NSDate date]];
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

-(UIBarButtonItem *)cancelButton {
    if (_cancelButton == nil) {
        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
        _cancelButton.tintColor = [UIColor whiteColor];
    }
    return _cancelButton;
}

-(UIImage *)paypointLogo {
    NSURL *url = [[PAYPOINT_SDK_BUNDLE_URL URLByAppendingPathComponent:@"PaypointLogo"] URLByAppendingPathExtension:@"png"];
    return [UIImage imageWithContentsOfFile:url.path];
}

#pragma mark - Actions

-(void)cancelButtonPressed:(UIBarButtonItem*)button {
    [self.delegate userCancelledCardFormEntry];
}

-(void)doneButtonPressed:(UIBarButtonItem*)button {
    [self.view endEditing:YES];
    self.navigationItem.rightBarButtonItem = nil;
}

-(void)backgroundTapped:(UITapGestureRecognizer*)gesture {
    [self.view endEditing:YES];
    self.navigationItem.rightBarButtonItem = nil;
}

-(IBAction)secureSwitchValueChanged:(UISwitch *)sender {
    self.details.secure = @(sender.isOn);
}

-(IBAction)payNowButtonPressed:(UIButton *)sender {
    
    PPOReachability *networkReachability = [PPOReachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        [self showAlertWithMessage:@"There is no internet connection"];
        [self.delegate userCompletedCardFormEntry:nil];
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

-(void)makePaymentWithDetails:(PPOPaymentForm*)details {
    
    [PPOPaymentController postCard:details.cardNumber withCVV:details.cvv withExpiry:details.expiry using3DSecure:details.secure.boolValue withCompletion:^(NSString *message, NSURL *redirect, NSData *data) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (redirect && data) {
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:redirect cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
                [request setHTTPMethod:@"POST"];
                [request setHTTPBody:data];
                
                PPOWebViewController *controller = [[PPOWebViewController alloc] initWithRequest:[request copy]];
                controller.delegate = self;
                PPONavigationViewController *navCon = [[PPONavigationViewController alloc] initWithRootViewController:controller];
                [self presentViewController:navCon animated:YES completion:nil];
            } else {
                [self.delegate userCompletedCardFormEntry:message];
            }
            
        });
        
    }];
    
}

-(void)showAlertWithMessage:(NSString*)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Outcome" message:message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - PPOPaymentController

-(void)completed:(NSString *)paRes transactionID:(NSString *)transID {
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        [PPOPaymentController resumePayment:paRes withTransactionID:transID withCompletion:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSString *message = @"Unknown outcome";
            
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            
            id outcome = [json objectForKey:@"outcome"];
            if ([outcome isKindOfClass:[NSDictionary class]]) {
                id m = [outcome objectForKey:@"reasonMessage"];
                if ([m isKindOfClass:[NSString class]]) {
                    message = m;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate userCompletedCardFormEntry:message];
            });
            
        }];
        
    }];
    
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
