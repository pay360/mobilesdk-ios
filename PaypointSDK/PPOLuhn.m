//
//  Luhn.m
//  Luhn Algorithm (Mod 10)
//
//  Created by Max Kramer on 30/12/2012.
//  Copyright (c) 2012 Max Kramer. All rights reserved.
//

#import "PPOLuhn.h"

@implementation PPOLuhn

+ (LuhnOLCreditCardType)typeFromString:(NSString *) string {
    BOOL valid = [PPOLuhn validateString:string];
    if (!valid) {
        return LuhnOLCreditCardTypeInvalid;
    }
    
    NSString *formattedString = [PPOLuhn formattedStringForProcessing:string];
    if (formattedString == nil || formattedString.length < 9) {
        return LuhnOLCreditCardTypeInvalid;
    }
    
    NSArray *enums = @[@(LuhnOLCreditCardTypeAmex), @(LuhnOLCreditCardTypeDinersClub), @(LuhnOLCreditCardTypeDiscover), @(LuhnOLCreditCardTypeJCB), @(LuhnOLCreditCardTypeMastercard), @(LuhnOLCreditCardTypeVisa)];
    
    __block LuhnOLCreditCardType type = LuhnOLCreditCardTypeInvalid;
    [enums enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        LuhnOLCreditCardType _type = [obj integerValue];
        NSPredicate *predicate = [PPOLuhn predicateForType:_type];
        BOOL isCurrentType = [predicate evaluateWithObject:formattedString];
        if (isCurrentType) {
            type = _type;
            *stop = YES;
        }
    }];
    return type;
}

+ (NSPredicate *)predicateForType:(LuhnOLCreditCardType) type {
    if (type == LuhnOLCreditCardTypeInvalid || type == LuhnOLCreditCardTypeUnsupported) {
        return nil;
    }
    NSString *regex = nil;
    switch (type) {
        case LuhnOLCreditCardTypeAmex:
            regex = @"^3[47][0-9]{5,}$";
            break;
        case LuhnOLCreditCardTypeDinersClub:
            regex = @"^3(?:0[0-5]|[68][0-9])[0-9]{4,}$";
            break;
        case LuhnOLCreditCardTypeDiscover:
            regex = @"^6(?:011|5[0-9]{2})[0-9]{3,}$";
            break;
        case LuhnOLCreditCardTypeJCB:
            regex = @"^(?:2131|1800|35[0-9]{3})[0-9]{3,}$";
            break;
        case LuhnOLCreditCardTypeMastercard:
            regex = @"^5[1-5][0-9]{5,}$";
            break;
        case LuhnOLCreditCardTypeVisa:
            regex = @"^4[0-9]{6,}$";
            break;
        default:
            break;
    }
    return [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
}

+ (BOOL)validateString:(NSString *)string forType:(LuhnOLCreditCardType)type {
    return [PPOLuhn typeFromString:string] == type;
}

+ (BOOL)validateString:(NSString *)string {
    NSString *formattedString = [PPOLuhn formattedStringForProcessing:string];
    if (formattedString == nil || formattedString.length < 9) {
        return NO;
    }
    
    NSMutableString *reversedString = [NSMutableString stringWithCapacity:[formattedString length]];
    
    [formattedString enumerateSubstringsInRange:NSMakeRange(0, [formattedString length]) options:(NSStringEnumerationReverse |NSStringEnumerationByComposedCharacterSequences) usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        [reversedString appendString:substring];
    }];
    
    NSUInteger oddSum = 0, evenSum = 0;
    
    for (NSUInteger i = 0; i < [reversedString length]; i++) {
        NSInteger digit = [[NSString stringWithFormat:@"%C", [reversedString characterAtIndex:i]] integerValue];
        
        if (i % 2 == 0) {
            evenSum += digit;
        }
        else {
            oddSum += digit / 5 + (2 * digit) % 10;
        }
    }
    return (oddSum + evenSum) % 10 == 0;
}

+ (NSString *)formattedStringForProcessing:(NSString*)string {
    NSCharacterSet *illegalCharacters = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSArray *components = [string componentsSeparatedByCharactersInSet:illegalCharacters];
    return [components componentsJoinedByString:@""];
}

@end