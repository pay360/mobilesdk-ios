//
//  PPODeviceInfo.m
//  Pay360
//
//  Created by Robert Nash on 18/05/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import "PPODeviceInfo.h"
#import "PPOSDKConstants.h"
#import <sys/types.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>
#import "PPOResourcesManager.h"

@interface PPODeviceInfo ()
@property (nonatomic, copy) NSString *uniqueIdentifier;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, copy) NSString *modelFamily;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *screenRes;
@end

@implementation PPODeviceInfo

-(NSString *)uniqueIdentifier {
    if (_uniqueIdentifier == nil) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *value = [userDefaults valueForKey:PPO_UNIQUE_IDENTIFIER];
        if (value && [value isKindOfClass:[NSString class]] && value.length > 0) {
            _uniqueIdentifier = value;
        } else {
            value = [NSUUID UUID].UUIDString;
            [userDefaults setValue:value forKey:PPO_UNIQUE_IDENTIFIER];
            _uniqueIdentifier = value;
        }
    }
    return _uniqueIdentifier;
}

-(NSString *)model {
    if (_model == nil) {
        NSString *desc = [self hardwareDescription];
        if (desc) {
            _model = desc;
        } else {
            _model = [[UIDevice currentDevice] model];
        }
    }
    return _model;
}

-(NSString *)modelFamily {
    
    if (_modelFamily == nil) {
        
        if ([self.model rangeOfString:@"iPod"].location != NSNotFound) {
            _modelFamily = @"iPod";
        } else if ([self.model rangeOfString:@"iPad"].location != NSNotFound) {
            _modelFamily = @"iPad";
        } else if ([self.model rangeOfString:@"iPhone"].location != NSNotFound) {
            _modelFamily = @"iPhone";
        } else if ([self.model rangeOfString:@"Simulator"].location != NSNotFound) {
            _modelFamily = @"Simulator";
        }
        
        _modelFamily = self.model;
    }
    return _modelFamily;
}

-(NSString *)type {
    if (_type == nil) {
        if ([self.modelFamily rangeOfString:@"iPad"].location != NSNotFound) {
            _type = @"TABLET";
        } else if ([self.modelFamily rangeOfString:@"iPhone"].location != NSNotFound) {
            _type = @"SMARTPHONE";
        } else {
            _type = @"OTHER";
        }
    }
    return _type;
}

-(NSString *)screenRes {
    if (_screenRes == nil) {
        CGFloat scale = [UIScreen mainScreen].scale;
        
        NSString *value1 = [NSString stringWithFormat:@"%.0f", [UIScreen mainScreen].bounds.size.width*scale];
        NSString *value2 = [NSString stringWithFormat:@"%.0f", [UIScreen mainScreen].bounds.size.height*scale];
        
        if (value1.floatValue > value2.floatValue) {
            _screenRes = [NSString stringWithFormat:@"%@x%@", value2, value1];
        } else {
            _screenRes = [NSString stringWithFormat:@"%@x%@", value1, value2];
        }
        
    }
    return _screenRes;
}

-(NSNumber*)dpi {
    
    CGFloat scale = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scale = [[UIScreen mainScreen] scale];
    }
    CGFloat dpi = 160 * scale;
    
    return @(dpi);
    
}

+(NSDictionary*)infoPlist {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    return [NSDictionary dictionaryWithContentsOfFile:path];
}

-(NSDictionary*)jsonObjectRepresentation {
    id uniqueIdentifier = (self.uniqueIdentifier) ?: [NSNull null];
    id osFamily = @"IOS";
    id osName = [NSString stringWithFormat:@"iOS %@", [[UIDevice currentDevice] systemVersion]];
    id modelName = (self.model) ?: @"unknown";
    id modelFamily = (self.modelFamily) ?: @"unknown";
    id manufacturer = @"Apple";
    id type = self.type;
    id screenRes = self.screenRes;
    id screenDPI = [self dpi];
    
    return @{
             @"sdkInstallId" : uniqueIdentifier,
             @"osFamily" : osFamily,
             @"osName" : osName,
             @"modelName" : modelName,
             @"modelFamily" : modelFamily,
             @"manufacturer" : manufacturer,
             @"type" : type,
             @"screenRes" : screenRes,
             @"screenDpi" : screenDPI
             };
}

- (NSString*)hardwareDescription {
    
    // iphone 6 and 6 plus return iphone7,2 and iphone7,1
    
    NSString *hardware = [self hardwareString];
    if ([hardware isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";
    if ([hardware isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
    if ([hardware isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
    if ([hardware isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
    if ([hardware isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
    if ([hardware isEqualToString:@"iPhone3,3"]) return @"iPhone 4 (CDMA)";
    if ([hardware isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
    if ([hardware isEqualToString:@"iPhone5,1"]) return @"iPhone 5";
    if ([hardware isEqualToString:@"iPhone5,2"]) return @"iPhone 5 (GSM+CDMA)";
    
    if ([hardware isEqualToString:@"iPhone7,1"]) return @"iPhone 6+";
    if ([hardware isEqualToString:@"iPhone7,2"]) return @"iPhone 6";
    
    if ([hardware isEqualToString:@"iPod1,1"]) return @"iPod Touch (1 Gen)";
    if ([hardware isEqualToString:@"iPod2,1"]) return @"iPod Touch (2 Gen)";
    if ([hardware isEqualToString:@"iPod3,1"]) return @"iPod Touch (3 Gen)";
    if ([hardware isEqualToString:@"iPod4,1"]) return @"iPod Touch (4 Gen)";
    if ([hardware isEqualToString:@"iPod5,1"]) return @"iPod Touch (5 Gen)";
    
    if ([hardware isEqualToString:@"iPad1,1"]) return @"iPad";
    if ([hardware isEqualToString:@"iPad1,2"]) return @"iPad 3G";
    if ([hardware isEqualToString:@"iPad2,1"]) return @"iPad 2 (WiFi)";
    if ([hardware isEqualToString:@"iPad2,2"]) return @"iPad 2";
    if ([hardware isEqualToString:@"iPad2,3"]) return @"iPad 2 (CDMA)";
    if ([hardware isEqualToString:@"iPad2,4"]) return @"iPad 2";
    if ([hardware isEqualToString:@"iPad2,5"]) return @"iPad Mini (WiFi)";
    if ([hardware isEqualToString:@"iPad2,6"]) return @"iPad Mini";
    if ([hardware isEqualToString:@"iPad2,7"]) return @"iPad Mini (GSM+CDMA)";
    if ([hardware isEqualToString:@"iPad3,1"]) return @"iPad 3 (WiFi)";
    if ([hardware isEqualToString:@"iPad3,2"]) return @"iPad 3 (GSM+CDMA)";
    if ([hardware isEqualToString:@"iPad3,3"]) return @"iPad 3";
    if ([hardware isEqualToString:@"iPad3,4"]) return @"iPad 4 (WiFi)";
    if ([hardware isEqualToString:@"iPad3,5"]) return @"iPad 4";
    if ([hardware isEqualToString:@"iPad3,6"]) return @"iPad 4 (GSM+CDMA)";
    
    if ([hardware isEqualToString:@"i386"]) return @"Simulator";
    if ([hardware isEqualToString:@"x86_64"]) return @"Simulator";
    
    return nil;
}

- (NSString*)hardwareString {
    size_t size = 100;
    char *hw_machine = malloc(size);
    int name[] = {CTL_HW,HW_MACHINE};
    sysctl(name, 2, hw_machine, &size, NULL, 0);
    NSString *hardware = [NSString stringWithUTF8String:hw_machine];
    free(hw_machine);
    return hardware;
}

@end
