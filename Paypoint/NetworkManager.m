//
//  NetworkManager.m
//  Paypoint
//
//  Created by Robert Nash on 08/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "NetworkManager.h"
#import "EnvironmentManager.h"

@implementation NetworkManager

+(void)getCredentialsWithCompletion:(void(^)(PPOCredentials *credentials, NSURLResponse *response, NSError *error))completion {
    
    __block NSString *token;
    __block PPOCredentials *c;
    
    PPOEnvironment environment = [EnvironmentManager currentEnvironment];
    
    NSURL *baseURL = [self baseURL:environment];
    NSURL *url = [baseURL URLByAppendingPathComponent:@"/merchant/getToken"];
        
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0f];
    
    [request setHTTPMethod:@"POST"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (((NSHTTPURLResponse*)response).statusCode == 200) {
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            id t = [json objectForKey:@"accessToken"];
            if ([t isKindOfClass:[NSString class]]) {
                token = t;
            }
        }
        
        if (token.length > 0) {
            c = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:token];
        }
        
        completion(c, response, error);
        
    }];
    
    [task resume];
    
}

@end
