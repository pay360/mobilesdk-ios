//
//  PPOCustomField.h
//  Paypoint
//
//  Created by Robert Nash on 19/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOCustomField : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, strong) NSNumber *isTransient; //Bool

-(NSDictionary*)jsonObjectRepresentation;

@end
