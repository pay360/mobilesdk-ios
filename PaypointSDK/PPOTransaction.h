//
//  PPOTransaction.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOTransaction : NSObject
@property (nonatomic, strong, readonly) NSString *currency;
@property (nonatomic, strong, readonly) NSNumber *amount;
@property (nonatomic, strong, readonly) NSString *transactionDescription;
@property (nonatomic, strong, readonly) NSString *merchantRef;
@property (nonatomic, strong, readonly) NSNumber *isDeferred;

-(instancetype)initWithCurrency:(NSString*)currency withAmount:(NSNumber*)amount withDescription:(NSString*)description withMerchantReference:(NSString*)reference isDeferred:(BOOL)deferred; //Designated Initialiser

-(NSDictionary*)jsonObjectRepresentation;

@end
