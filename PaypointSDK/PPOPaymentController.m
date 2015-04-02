//
//  PaymentManager.m
//  Paypoint
//
//  Created by Robert Nash on 20/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentController.h"
#import "PPONavigationViewController.h"
#import "PPOFormViewController.h"

@interface PPOPaymentController () <NSURLSessionTaskDelegate>
@property (nonatomic, strong, readwrite) NSOperationQueue *paymentQueue;
@end

@implementation PPOPaymentController

+(instancetype)sharedInsance {
    static id sharedInsance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInsance = [[[self class] alloc] init];
    });
    return sharedInsance;
}

+(UINavigationController*)paymentFlowWithDelegate:(id<PPOPaymentControllerProtocol>)delegate {
    PPOFormViewController *controller = [[PPOFormViewController alloc] initWithDelegate:delegate];
    PPONavigationViewController *navCon = [[PPONavigationViewController alloc] initWithRootViewController:controller];
    return navCon;
}

#pragma mark - Networking

-(NSOperationQueue *)paymentQueue {
    if (_paymentQueue == nil) {
        _paymentQueue = [NSOperationQueue new];
        _paymentQueue.name = @"Payments_Queue";
        _paymentQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    }
    return _paymentQueue;
}

#pragma mark - Request

+(NSURLRequest*)requestWithCredentials:(NSURL*)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [request setValue:[PPOPaymentController authorisationValue] forHTTPHeaderField:@"Authorization"];
    return [request copy];
}

+(NSString*)authorisationValue {
    NSData *data = [[NSString stringWithFormat:@"%@:%@", @"3PMY3DIR5RGRJO3F62IAOH3WZM", @"ylsmbaWtlz+EWJymuq1Nhg=="] dataUsingEncoding:NSASCIIStringEncoding];
    return [NSString stringWithFormat:@"Basic %@", [data base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength]];
}

+(void)postCard:(NSString*)card
        withCVV:(NSString*)cvv
     withExpiry:(NSString*)expiry
  using3DSecure:(BOOL)secure
 withCompletion:(void(^)(NSString *message, NSURL *redirect, NSData *data))completion {
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:[PPOPaymentController sharedInsance]
                                                     delegateQueue:[PPOPaymentController sharedInsance].paymentQueue];
    
    NSData *data = [PPOPaymentController staticDataWithCardNumber:card withCVV:cvv withExpiryData:expiry use3DSecure:secure];
    
    NSMutableURLRequest *request = [[PPOPaymentController requestWithCredentials:[NSURL URLWithString:@"https://api.mite.paypoint.net:2443/acceptor/rest/transactions/5300129/payment"]] mutableCopy];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:[request copy] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        BOOL is3DSecure = NO;
        NSString *transactionID;
        NSString *message;
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if ([json isKindOfClass:[NSDictionary class]]) {
            
            id trans = [json objectForKey:@"transaction"];
            if ([trans isKindOfClass:[NSDictionary class]]) {
                id transID = [trans objectForKey:@"transactionId"];
                if ([transID isKindOfClass:[NSString class]]) {
                    transactionID = transID;
                }
            }
            
            id outcome = [json objectForKey:@"outcome"];
            if ([outcome isKindOfClass:[NSDictionary class]]) {
                id c = [outcome objectForKey:@"reasonCode"];
                if ([c isKindOfClass:[NSString class]]) {
                    is3DSecure = [c isEqualToString:@"U100"];
                }
                id m = [outcome objectForKey:@"reasonMessage"];
                if ([m isKindOfClass:[NSString class]]) {
                    message = m;
                }
            }
            
        }
        
        if (is3DSecure) {
            NSString *paReq;
            NSURL *redirectURL;
            
            id cRedirect = [json objectForKey:@"clientRedirect"];
            if ([cRedirect isKindOfClass:[NSDictionary class]]) {
                paReq = [cRedirect objectForKey:@"pareq"];
                id redirect = [cRedirect objectForKey:@"url"];
                if ([redirect isKindOfClass:[NSString class]]) {
                    redirectURL = [NSURL URLWithString:redirect];
                }
            }
            
            NSString *string = [NSString stringWithFormat:@"PaReq=%@&MD=%@&TermUrl=%@", [PPOPaymentController urlencode:paReq], [PPOPaymentController urlencode:transactionID], @"appscheme://stop"];
            NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
            
            completion(message, redirectURL, data);
        } else {
            completion(message, nil, nil);
        }
    }];

    [task resume];
}

+(void)resumePayment:(NSString*)paRes
   withTransactionID:(NSString*)transID
      withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:[PPOPaymentController sharedInsance]
                                                     delegateQueue:[PPOPaymentController sharedInsance].paymentQueue];
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.mite.paypoint.net:2443/acceptor/rest/transactions/5300129/%@/resume", transID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[PPOPaymentController requestWithCredentials:url] mutableCopy];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[self staticDataWithPaRes:paRes]];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:completion];
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

#pragma mark - Static Data

+(NSData*)staticDataWithCardNumber:(NSString*)card withCVV:(NSString*)cvv withExpiryData:(NSString*)expiry use3DSecure:(BOOL)secure {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"SimplePayment" ofType:@"json"];
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    [json setValue:card forKeyPath:@"paymentMethod.card.pan"];
    [json setValue:cvv forKeyPath:@"paymentMethod.card.cv2"];
    [json setValue:expiry forKeyPath:@"paymentMethod.card.expiryDate"];
    [json setValue:@(secure) forKeyPath:@"transactionOptions.do3DSecure"];
    return [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
}

+(NSData*)staticDataWithPaRes:(NSString*)paRes {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Resume" ofType:@"json"];
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    [json setValue:paRes forKeyPath:@"threeDSecureResponse.pares"];
    return [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
}

#pragma mark - NSURLSessionDataTaskProtocol

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"%@ NSURLSession didCompleteWithError: %@", [self class], error);
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    NSLog(@"%@ NSURLSession didReceiveChallenge: %@", [self class], challenge);
    
//    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
//    {
//        SecTrustResultType result;
//        //This takes the serverTrust object and checkes it against your keychain
//        SecTrustEvaluate(challenge.protectionSpace.serverTrust, &result);
//        
//        //If allow invalid certs, end here
//        //completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
//        
//        //When testing this against a trusted server I got kSecTrustResultUnspecified every time. But the other two match the description of a trusted server
//        if(result == kSecTrustResultProceed ||  result == kSecTrustResultUnspecified){
//            completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
//        }
//        else {
//            //Asks the user for trust
//            if (YES) {
//                //May need to add a method to add serverTrust to the keychain like Firefox's "Add Excpetion"
//                completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
//            }
//            else {
//                [[challenge sender] cancelAuthenticationChallenge:challenge];
//            }
//        }
//    }
//    else if ([[challenge protectionSpace] authenticationMethod] == NSURLAuthenticationMethodDefault) {
//        NSURLCredential *newCredential = [NSURLCredential credentialWithUser:@"" password:@"" persistence:NSURLCredentialPersistenceNone];
//        completionHandler(NSURLSessionAuthChallengeUseCredential, newCredential);
//    }
    
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    NSLog(@"didSendBodyData: %lli totalBytesSent: %lli totalBytesExpectedToSend: %lli", bytesSent, totalBytesSent, totalBytesExpectedToSend);
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *))completionHandler {
    NSLog(@"%@ NSURLSession task: %@", [self class], task);
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    NSLog(@"%@ NSURLSession task: %@ willPerformHTTPRedirection: %@ newRequest: %@", [self class], task, response, request);
}

@end
