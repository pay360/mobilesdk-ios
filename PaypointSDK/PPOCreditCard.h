//
//  PPOCreditCard.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOCreditCard : NSObject
@property (nonatomic, strong, readonly) NSString *pan;
@property (nonatomic, strong, readonly) NSString *cvv;
@property (nonatomic, strong, readonly) NSString *expiry;
@property (nonatomic, strong, readonly) NSString *cardHolderName;

-(instancetype)initWithPan:(NSString*)pan withSecurityCodeCode:(NSString*)cvv withExpiry:(NSString*)date withCardholderName:(NSString*)cardholder; //Designated Initialiser

-(NSDictionary*)jsonObjectRepresentation;

@end
