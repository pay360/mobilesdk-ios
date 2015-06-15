//
//  PPOCreditCard.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  @discussion An instance of this class represents a credit card.
 */
@interface PPOCreditCard : NSObject
@property (nonatomic, strong) NSString *pan;
@property (nonatomic, strong) NSString *cvv;
@property (nonatomic, strong) NSString *expiry;
@property (nonatomic, strong) NSString *cardHolderName;

-(NSDictionary*)jsonObjectRepresentation;

@end
