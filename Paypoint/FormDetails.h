//
//  FormDetails.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FormDetails : NSObject

@property (nonatomic, strong) NSString *cardNumber;
@property (nonatomic, strong) NSString *expiry;
@property (nonatomic, strong) NSString *cvv;

-(BOOL)isComplete;

@end
