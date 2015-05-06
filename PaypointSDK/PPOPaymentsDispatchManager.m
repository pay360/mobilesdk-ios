//
//  PPOPaymentsDispatchManager.m
//  Paypoint
//
//  Created by Robert Nash on 20/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentsDispatchManager.h"
#import "PPOWebViewController.h"
#import "PPOPayment.h"
#import "PPOCredentials.h"
#import "PPOErrorManager.h"

@interface PPOPaymentsDispatchManager () <NSURLSessionTaskDelegate, PPOWebViewControllerDelegate>
@property (nonatomic, strong, readwrite) NSOperationQueue *payments;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) void(^outcomeCompletion)(PPOOutcome *outcome, NSError *error);
@property (nonatomic) CGFloat timeout;
@property (nonatomic, strong) PPOCredentials *credentials;
@end

@implementation PPOPaymentsDispatchManager

-(NSOperationQueue *)payments {
    if (_payments == nil) {
        _payments = [NSOperationQueue new];
        _payments.name = @"Payments_Queue";
        _payments.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    }
    return _payments;
}

-(NSURLSession *)session {
    if (_session == nil) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.payments];
    }
    return _session;
}

-(void)dispatchRequest:(NSURLRequest*)request
           withTimeout:(CGFloat)timeout
       withCredentials:(PPOCredentials*)credentials
        withCompletion:(void (^)(PPOOutcome *outcome, NSError *error))completion {
    
    self.outcomeCompletion = completion;
    self.timeout = timeout;
    self.credentials = credentials;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
        
        id json;
        NSError *invalidJSON;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        if (invalidJSON) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                completion(nil, [PPOErrorManager errorForCode:PPOErrorServerFailure]);
            });
            return;
        }
        
        /* 
         Consider pulling out transaction here
         
         [json objectForKey:@"transaction"]
         
         transaction =     {
         amount = 1000;
         currency = GBP;
         merchantRef = "mer_1430832896";
         transactionId = 2120299066;
         transactionTime = "2015-05-05T13:34:56.933Z";
         type = PREAUTH;
         };
         
         and keeping the transaction id around to inspect it later on, just to be sure nothing wierd has happened
         
         */
        
        id value = [json objectForKey:@"threeDSRedirect"];
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSString *acsURLString = [value objectForKey:@"acsUrl"];
            if ([acsURLString isKindOfClass:[NSString class]]) {
                NSString *md = [value objectForKey:@"md"];
                NSString *pareq = [value objectForKey:@"pareq"];
                NSNumber *sessionTimeout = [value objectForKey:@"sessionTimeout"];
                NSTimeInterval secondsTimeout = sessionTimeout.doubleValue/1000;
                NSString *termUrlString = [value objectForKey:@"termUrl"];
                NSURL *termURL = [NSURL URLWithString:termUrlString];
                NSURL *acsURL = [NSURL URLWithString:acsURLString];
                if (acsURL) {
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:acsURL];
                    [request setHTTPMethod:@"POST"];
                    
                    NSString *string = [NSString stringWithFormat:@"PaReq=%@&MD=%@&TermUrl=%@", [PPOPaymentsDispatchManager urlencode:pareq], [PPOPaymentsDispatchManager urlencode:md], termURL];
                    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
                    
                    [request setHTTPBody:data];
                    
                    PPOWebViewController *controller = [[PPOWebViewController alloc] init];
                    controller.delegate = self;
                    controller.request = request;
                    controller.termURLString = termUrlString;
                    
                    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:controller];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:navCon animated:YES completion:nil];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                        completion(nil, [PPOErrorManager errorForCode:PPOErrorProcessingThreeDSecure]);
                    });
                }
            }
            return;
        }
        
        if (json) {
            NSError *error;
            PPOOutcome *outcome = [[PPOOutcome alloc] initWithData:json];
            if (outcome.isSuccessful == NO) {
                PPOErrorCode code = [PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue];
                error = [PPOErrorManager errorForCode:code];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                completion(outcome, error);
            });
        }
        
        if (networkError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                completion(nil, networkError);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                completion(nil, [PPOErrorManager errorForCode:PPOErrorUnknown]);
            });
        }
        
    }];
    
    [task resume];
    
}

+(NSString *)urlencode:(NSString*)string {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[string UTF8String];
    unsigned long sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
}

-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
}

#pragma mark - PPOWebViewController

-(void)completed:(NSString *)paRes transactionID:(NSString *)transID {
    
    id data;
    if (paRes) {
        NSDictionary *dictionary = @{@"threeDSecureResponse": @{@"pares":paRes}};
        data = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    }
#warning installation id hardcoded here
    NSURLSessionDataTask *task;
    NSString *urlString = [NSString stringWithFormat:@"http://localhost:5000/acceptor/rest/mobile/transactions/%@/%@/resume", @"5300065", transID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:self.timeout];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setValue:[self authorisation:self.credentials] forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:data];
    
    task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (((NSHTTPURLResponse*)response).statusCode == 200) {
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            PPOOutcome *outcome = [[PPOOutcome alloc] initWithData:json];
            if (outcome.isSuccessful == NO) {
                PPOErrorCode code = [PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue];
                error = [PPOErrorManager errorForCode:code];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [[[UIApplication sharedApplication] keyWindow].rootViewController dismissViewControllerAnimated:YES completion:^{
                    self.outcomeCompletion(outcome, error);
                }];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [[[UIApplication sharedApplication] keyWindow].rootViewController dismissViewControllerAnimated:YES completion:^{
                    self.outcomeCompletion(nil, [PPOErrorManager errorForCode:PPOErrorUnknown]);
                }];
            });
        }
        
    }];
    
    [task resume];
    
}

-(NSString*)authorisation:(PPOCredentials*)credentials {
    return [NSString stringWithFormat:@"Bearer %@", credentials.token];
}

@end
