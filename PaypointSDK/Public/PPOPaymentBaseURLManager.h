//
//  PPOPaymentBaseURLManager.h
//  Paypoint
//
//  Created by Robert Nash on 17/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 * @typedef PPOEnvironment
 * @brief Environments for payment processing.
 * @constant PPOEnvironmentMerchantIntegrationTestingEnvironment A testing environment.
 * @constant PPOEnvironmentMerchantIntegrationProductionEnvironment A production environment.
 * @constatn PPOEnvironmentTotalCount The total amount of available environments.
 */
typedef enum {
    PPOEnvironmentMerchantIntegrationTestingEnvironment,
    PPOEnvironmentMerchantIntegrationProductionEnvironment,
    PPOEnvironmentTotalCount
} PPOEnvironment;

/**
 * @brief For convenience, this class provides class method for generating a base URL, corresponding to each environment listed in the PPOEnvironment enum.
 */
@interface PPOPaymentBaseURLManager : NSObject

/**
 *  @brief This method generates the base url for the corresponding environment variable passed in.
 *
 *  @param environment An enum list of available environments.
 *
 *  @return The base URL for the corresponding environment.
 */
+(NSURL*)baseURLForEnvironment:(PPOEnvironment)environment;

@end
