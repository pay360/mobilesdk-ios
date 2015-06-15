//
//  PPOCustomField.h
//  Paypoint
//
//  Created by Robert Nash on 19/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  @discussion An instance of this class represents a custom field.
 */
@interface PPOCustomField : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, strong) NSNumber *isTransient;

-(NSDictionary*)jsonObjectRepresentation;

@end
