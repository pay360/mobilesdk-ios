//
//  PPOTransaction.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * @discussion An instance of this class represents a transaction. Set 'isDeferred' to 'YES' for pre-authentication.
 */
@interface PPOTransaction : NSObject
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSNumber *amount;
@property (nonatomic, strong) NSString *transactionDescription;
@property (nonatomic, strong) NSString *merchantRef;
@property (nonatomic, strong) NSNumber *isDeferred;

-(NSDictionary*)jsonObjectRepresentation;

@end
