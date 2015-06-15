//
//  PPOFinancialService.h
//  Paypoint
//
//  Created by Robert Nash on 19/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  @discussion An instance of this class represents a financial service.
 */
@interface PPOFinancialService : NSObject
@property (nonatomic, copy) NSString *dateOfBirth;
@property (nonatomic, copy) NSString *surname;
@property (nonatomic, copy) NSString *accountNumber;
@property (nonatomic, copy) NSString *postCode;

-(NSDictionary*)jsonObjectRepresentation;

@end
