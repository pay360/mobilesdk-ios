//
//  FormViewController.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "FormDetails.h"

typedef enum : NSUInteger {
    TEXT_FIELD_TYPE_CARD_NUMBER,
    TEXT_FIELD_TYPE_EXPIRY,
    TEXT_FIELD_TYPE_CVV
} TEXT_FIELD_TYPE;

@interface FormViewController : UIViewController <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *titleLabels;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UIView *blockerView;
@property (weak, nonatomic) IBOutlet UILabel *blockerLabel;
@property (weak, nonatomic) IBOutlet UIImageView *paypointLogoImageView;
@property (weak, nonatomic) IBOutlet UIButton *payNowButton;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) NSArray *pickerViewSelections;
@property (nonatomic, strong) FormDetails *details;

-(void)blockerTapGestureRecognised:(UITapGestureRecognizer*)gesture;

@end
