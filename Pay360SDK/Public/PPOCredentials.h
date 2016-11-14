//
//  PPOCredentials.h
//  Pay360
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
@class PPOCredentials
@discussion An instance of this class represents the credentials required for making a payment.
 */
@interface PPOCredentials : NSObject

@property (nonatomic, strong) NSString *installationID;

/*!
@discussion A client access token required for Authorising individual payments.
 */
@property (nonatomic, strong) NSString *token;

@end
