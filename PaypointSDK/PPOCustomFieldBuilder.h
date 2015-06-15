//
//  PPOCustomFieldBuilder.h
//  PayPointPayments
//
//  Created by Robert Nash on 15/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOCustomField.h"

@interface PPOCustomFieldBuilder : NSObject

+(PPOCustomField*)customFieldWithData:(NSDictionary*)data;

@end
