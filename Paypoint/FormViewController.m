//
//  FormViewController.m
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "FormViewController.h"
#import "TimeManager.h"
#import "ColourManager.h"
#import "ImageManager.h"
#import "ButtonStyler.h"

@interface FormViewController ()
@property (nonatomic, strong) TimeManager *timeController;
@property (nonatomic, strong) NSString *previousTextFieldContent;
@property (nonatomic, strong) UITextRange *previousSelection;
@property (nonatomic, readwrite) LOADING_ANIMATION_STATE animationState;
@property (nonatomic, copy) void(^endAnimationCompletion)(void);
@end

@implementation FormViewController {
    BOOL _animationShouldEndAsSoonHasItHasFinishedStarting;
}

-(TimeManager *)timeController {
    if (_timeController == nil) {
        _timeController = [TimeManager new];
    }
    return _timeController;
}

-(FormDetails *)form {
    if (_form == nil) {
        _form = [FormDetails new];
    }
    return _form;
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
    
    self.animationState = LOADING_ANIMATION_STATE_ENDED;
    
    self.title = @"Details";
    
    for (UITextField *textField in self.textFields) {
        textField.delegate = self;
        textField.textColor = [ColourManager ppBlue];
        
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 20)];
        textField.leftView = paddingView;
        textField.leftViewMode = UITextFieldViewModeAlways;
    }
    
    [ButtonStyler styleButton:self.payNowButton];
    
    UITapGestureRecognizer *tap;
    
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    [self.view addGestureRecognizer:tap];
    
    UIColor *blue = [ColourManager ppBlue];
    
    self.amountLabel.textColor = blue;
    
    for (UILabel *titleLabel in self.titleLabels) {
        titleLabel.textColor = blue;
    }
    
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(blockerTapGestureRecognised:)];
    [self.blockerView addGestureRecognizer:tap];
    
//    self.view.backgroundColor = [ColourManager ppLightGrey:1];

}

-(void)blockerTapGestureRecognised:(UITapGestureRecognizer*)gesture {
    
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

- (IBAction)textFieldEditingChanged:(UITextField *)sender
                           forEvent:(UIEvent *)event {
    
    switch (sender.tag) {
        case TEXT_FIELD_TYPE_CARD_NUMBER: {
            self.form.cardNumber = sender.text;
            [self reformatAsCardNumber:sender];
        }
            break;
        case TEXT_FIELD_TYPE_CVV:
            self.form.cvv = sender.text;
            break;
        default:
            break;
    }
    
}

#pragma mark - UITextField Four Digit Spacing

// Source and explanation: http://stackoverflow.com/a/19161529/1709587
-(void)reformatAsCardNumber:(UITextField *)textField
{
    // In order to make the cursor end up positioned correctly, we need to
    // explicitly reposition it after we inject spaces into the text.
    // targetCursorPosition keeps track of where the cursor needs to end up as
    // we modify the string, and at the end we set the cursor position to it.
    NSUInteger targetCursorPosition =
    [textField offsetFromPosition:textField.beginningOfDocument
                       toPosition:textField.selectedTextRange.start];
    
    NSString *cardNumberWithoutSpaces =
    [self removeNonDigits:textField.text
andPreserveCursorPosition:&targetCursorPosition];
    
    if ([cardNumberWithoutSpaces length] > 19) {
        // If the user is trying to enter more than 19 digits, we prevent
        // their change, leaving the text field in  its previous state.
        // While 16 digits is usual, credit card numbers have a hard
        // maximum of 19 digits defined by ISO standard 7812-1 in section
        // 3.8 and elsewhere. Applying this hard maximum here rather than
        // a maximum of 16 ensures that users with unusual card numbers
        // will still be able to enter their card number even if the
        // resultant formatting is odd.
        [textField setText:_previousTextFieldContent];
        textField.selectedTextRange = _previousSelection;
        return;
    }
    
    NSString *cardNumberWithSpaces =
    [self insertSpacesEveryFourDigitsIntoString:cardNumberWithoutSpaces
                      andPreserveCursorPosition:&targetCursorPosition];
    
    textField.text = cardNumberWithSpaces;
    UITextPosition *targetPosition =
    [textField positionFromPosition:[textField beginningOfDocument]
                             offset:targetCursorPosition];
    
    [textField setSelectedTextRange:
     [textField textRangeFromPosition:targetPosition
                           toPosition:targetPosition]
     ];
}

-(BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
    // Note textField's current state before performing the change, in case
    // reformatTextField wants to revert it
    self.previousTextFieldContent = textField.text;
    self.previousSelection = textField.selectedTextRange;
    
    return YES;
}

/*
 Removes non-digits from the string, decrementing `cursorPosition` as
 appropriate so that, for instance, if we pass in `@"1111 1123 1111"`
 and a cursor position of `8`, the cursor position will be changed to
 `7` (keeping it between the '2' and the '3' after the spaces are removed).
 */
- (NSString *)removeNonDigits:(NSString *)string
    andPreserveCursorPosition:(NSUInteger *)cursorPosition
{
    NSUInteger originalCursorPosition = *cursorPosition;
    NSMutableString *digitsOnlyString = [NSMutableString new];
    for (NSUInteger i=0; i<[string length]; i++) {
        unichar characterToAdd = [string characterAtIndex:i];
        if (isdigit(characterToAdd)) {
            NSString *stringToAdd =
            [NSString stringWithCharacters:&characterToAdd
                                    length:1];
            
            [digitsOnlyString appendString:stringToAdd];
        }
        else {
            if (i < originalCursorPosition) {
                (*cursorPosition)--;
            }
        }
    }
    
    return digitsOnlyString;
}

/*
 Inserts spaces into the string to format it as a credit card number,
 incrementing `cursorPosition` as appropriate so that, for instance, if we
 pass in `@"111111231111"` and a cursor position of `7`, the cursor position
 will be changed to `8` (keeping it between the '2' and the '3' after the
 spaces are added).
 */
- (NSString *)insertSpacesEveryFourDigitsIntoString:(NSString *)string
                          andPreserveCursorPosition:(NSUInteger *)cursorPosition
{
    NSMutableString *stringWithAddedSpaces = [NSMutableString new];
    NSUInteger cursorPositionInSpacelessString = *cursorPosition;
    for (NSUInteger i=0; i<[string length]; i++) {
        if ((i>0) && ((i % 4) == 0)) {
            [stringWithAddedSpaces appendString:@" "];
            if (i < cursorPositionInSpacelessString) {
                (*cursorPosition)++;
            }
        }
        unichar characterToAdd = [string characterAtIndex:i];
        NSString *stringToAdd =
        [NSString stringWithCharacters:&characterToAdd length:1];
        
        [stringWithAddedSpaces appendString:stringToAdd];
    }
    
    return stringWithAddedSpaces;
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
            self.form.expiry = date;
        }
    }
    
    return YES;
}

-(BOOL)textFieldShouldClear:(UITextField *)textField {
    textField.text = nil;
    
    switch (textField.tag) {
        case TEXT_FIELD_TYPE_CARD_NUMBER:
            self.form.cardNumber = nil;
            break;
        case TEXT_FIELD_TYPE_EXPIRY:
            self.form.expiry = nil;
            break;
        case TEXT_FIELD_TYPE_CVV:
            self.form.cvv = nil;
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
    self.form.expiry = dateString;
}

#pragma mark - Animation

-(void)beginAnimation {
    
    _animationState = LOADING_ANIMATION_STATE_STARTING;
    
    NSTimeInterval duration = 1.0;
    
    self.blockerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    self.blockerView.hidden = NO;
    
    [UIView animateWithDuration:duration/6 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        
        self.blockerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.4];
        
        self.paypointLogoImageView.transform = CGAffineTransformMakeScale(1.9, 1.9);
        
    } completion:^(BOOL finished) {
        
        _animationState = LOADING_ANIMATION_STATE_IN_PROGRESS;
        
        self.blockerLabel.hidden = NO;
        
        [UIView animateWithDuration:duration/2 animations:^{
            self.blockerLabel.alpha = 1;
        }];
        
        [UIView animateKeyframesWithDuration:duration/2 delay:0.0 options:UIViewKeyframeAnimationOptionRepeat animations:^{
            
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.5 animations:^{
                self.paypointLogoImageView.transform = CGAffineTransformMakeScale(2.2, 2.2);
            }];
            
            [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
                self.paypointLogoImageView.transform = CGAffineTransformMakeScale(1.9, 1.9);
            }];
            
        } completion:^(BOOL finished) {
        }];
        
        if (_animationShouldEndAsSoonHasItHasFinishedStarting) {
            [self endAnimationWithCompletion:self.endAnimationCompletion];
        }
        
    }];
    
}

-(void)endAnimationWithCompletion:(void(^)(void))completion {
    
    self.endAnimationCompletion = completion;
    
    if (_animationState == LOADING_ANIMATION_STATE_ENDED) {
        if (self.endAnimationCompletion) self.endAnimationCompletion();
        return;
    }
    
    if (_animationState == LOADING_ANIMATION_STATE_IN_PROGRESS) {
        
        _animationState = LOADING_ANIMATION_STATE_ENDING;
        
        [self.paypointLogoImageView.layer removeAllAnimations];
        
        CALayer *currentLayer = self.paypointLogoImageView.layer.presentationLayer;
        
        self.paypointLogoImageView.layer.transform = currentLayer.transform;
        
        [UIView animateWithDuration:.6 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            
            self.blockerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
            self.blockerLabel.alpha = 0;
            
            self.paypointLogoImageView.transform = CGAffineTransformIdentity;
            
        } completion:^(BOOL finished) {
            
            self.blockerView.hidden = YES;
            self.blockerLabel.hidden = YES;
            
            _animationState = LOADING_ANIMATION_STATE_ENDED;
            
            _animationShouldEndAsSoonHasItHasFinishedStarting = NO;
            
            if (completion) completion();
            
        }];
        
    } else {
        _animationShouldEndAsSoonHasItHasFinishedStarting = YES;
    }
    
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
