//
//  PPOCustomFieldBuilder.h
//  Pay360Payments
//
//  Created by Robert Nash on 15/06/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import "PPOCustomField.h"

@interface PPOCustomFieldBuilder : NSObject

+(PPOCustomField*)customFieldWithData:(NSDictionary*)data;

@end
