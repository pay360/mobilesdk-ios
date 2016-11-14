//
//  PPOPaymentReference.h
//  Pay360Payments
//
//  Created by Robert Nash on 09/07/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOPaymentReference : NSObject

@property (nonatomic, readonly, copy) NSString *identifier;

-(instancetype)initWithIdentifier:(NSString *)identifer;

@end
