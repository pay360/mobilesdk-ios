//
//  Luhn.h
//  Luhn Algorithm (Mod 10)
//
//  Created by Max Kramer on 30/12/2012.
//  Copyright (c) 2012 Max Kramer. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LuhnOLCreditCardType) {
    LuhnOLCreditCardTypeAmex,
    LuhnOLCreditCardTypeVisa,
    LuhnOLCreditCardTypeMastercard,
    LuhnOLCreditCardTypeDiscover,
    LuhnOLCreditCardTypeDinersClub,
    LuhnOLCreditCardTypeJCB,
    LuhnOLCreditCardTypeUnsupported,
    LuhnOLCreditCardTypeInvalid
};

@interface PPOLuhn : NSObject

+(LuhnOLCreditCardType)typeFromString:(NSString *)string;
+(BOOL)validateString:(NSString *)string forType:(LuhnOLCreditCardType)type;
+(BOOL)validateString:(NSString *)string;

@end