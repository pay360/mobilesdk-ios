//
//  PPOPaymentBaseURLManager.h
//  Paypoint
//
//  Created by Robert Nash on 17/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PPOEnvironment) {
    PPOMerchantIntegrationTestingEnvironment
};

@interface PPOPaymentBaseURLManager : NSObject

+(NSURL*)baseURLForEnvironment:(PPOEnvironment)environment;

@end
