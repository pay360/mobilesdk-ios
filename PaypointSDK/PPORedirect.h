//
//  PPORedirect.h
//  Paypoint
//
//  Created by Robert Nash on 14/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPORedirect : NSObject

@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSNumber *sessionTimeoutTimeInterval;
@property (nonatomic, strong) NSNumber *delayTimeInterval;
@property (nonatomic, strong) NSURL *termURL;
@property (nonatomic, strong) NSString *transactionID;

-(instancetype)initWithData:(NSDictionary*)data;

@end
