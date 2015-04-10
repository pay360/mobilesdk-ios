//
//  PPOOutcome.h
//  Paypoint
//
//  Created by Robert Nash on 10/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOOutcome : NSObject

@property (nonatomic, strong, readonly) NSString *reasonMessage;
@property (nonatomic, strong, readonly) NSNumber *reasonCode;
@property (nonatomic, strong, readonly) NSString *status;

-(instancetype)initWithData:(NSDictionary*)data;

@end
