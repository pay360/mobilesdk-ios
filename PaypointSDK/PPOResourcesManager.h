//
//  PPOResourcesManager.h
//  Paypoint
//
//  Created by Robert Nash on 12/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOResourcesManager : NSObject

+(NSBundle*)resources;
+(NSDictionary*)frameworkVersion;
+(NSNumber*)frameworkBuild;

@end
