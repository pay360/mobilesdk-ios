//
//  PPOCustomer.h
//  Paypoint
//
//  Created by Robert Nash on 19/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOCustomer : NSObject
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *dateOfBirth;
@property (nonatomic, copy) NSString *telephone;

-(NSDictionary*)jsonObjectRepresentation;

@end
