//
//  PPOPaymentForm.h
//  Paypoint
//
//  Created by Robert Nash on 23/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPOPaymentForm : NSObject

@property (nonatomic, strong) NSString *cardNumber;
@property (nonatomic, strong) NSString *expiry;
@property (nonatomic, strong) NSString *cvv;
@property (nonatomic, strong) NSNumber *secure;

-(BOOL)isComplete;

@end
