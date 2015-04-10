//
//  FormViewController.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "FormViewController.h"
#import "TimeManager.h"

@interface FormViewController ()
@property (nonatomic, strong) TimeManager *timeController;
@end

@implementation FormViewController

-(TimeManager *)timeController {
    if (_timeController == nil) {
        _timeController = [TimeManager new];
    }
    return _timeController;
}

-(FormDetails *)details {
    if (_details == nil) {
        _details = [FormDetails new];
    }
    return _details;
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

-(void)viewDidLoad {
    
    [super viewDidLoad];
        
    self.title = @"Details";
    
    for (UITextField *textField in self.textFields) {
        textField.delegate = self;
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    [self.view addGestureRecognizer:tap];

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

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return ![string isEqualToString:@" "];
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
}

@end
