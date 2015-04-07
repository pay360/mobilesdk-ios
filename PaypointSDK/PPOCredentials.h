//
//  PPOCredentials.h
//  Paypoint
//
//  Created by Robert Nash on 07/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOCredentials : NSObject
@property (nonatomic, strong, readonly) NSString *installationID;
@property (nonatomic, strong, readonly) NSString *token;

-(instancetype)initWithID:(NSString*)installationID withToken:(NSString*)token; //Designated Initialiser

@end
