//
//  PPOWebFormDelegate.m
//  Paypoint
//
//  Created by Robert Nash on 01/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOWebFormManager.h"
#import "PPOWebViewController.h"
#import "PPORedirect.h"
#import "PPOPaymentTrackingManager.h"
#import "PPOPaymentEndpointManager.h"
#import "PPOCredentials.h"
#import "PPOErrorManager.h"

@interface PPOWebFormManager () <PPOWebViewControllerDelegate>
@property (nonatomic, strong) PPORedirect *redirect;
@property (nonatomic, copy) void(^outcomeHandler)(PPOOutcome *outcome, NSError *error);
@property (nonatomic, strong) PPOWebViewController *webController;
@property (nonatomic, strong) PPOPaymentEndpointManager *endpointManager;
@property (nonatomic, strong) PPOCredentials *credentials;
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation PPOWebFormManager  {
    BOOL _preventShowWebView;
    BOOL _isDismissingWebView;
}

-(instancetype)initWithRedirect:(PPORedirect *)redirect
                withCredentials:(PPOCredentials*)credentials
                    withSession:(NSURLSession*)session
            withEndpointManager:(PPOPaymentEndpointManager*)endpointManager
                    withOutcome:(void(^)(PPOOutcome *outcome, NSError *error))outcomeHandler {
    self = [super init];
    if (self) {
        _credentials = credentials;
        _endpointManager = endpointManager;
        _outcomeHandler = outcomeHandler;
        _session = session;
        _redirect = redirect;
        [self loadRedirect:redirect];
    }
    return self;
}

-(void)loadRedirect:(PPORedirect*)redirect {
    self.webController = [[PPOWebViewController alloc] initWithRedirect:redirect withDelegate:self];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    self.webController.view.frame = CGRectMake(-height, -width, width, height);
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.webController.view];
}

#pragma mark - PPOWebViewController

-(void)webViewController:(PPOWebViewController *)controller completedWithPaRes:(NSString *)paRes forTransactionWithID:(NSString *)transID {
    
    _preventShowWebView = YES;
    
    [PPOPaymentTrackingManager resumeTimeoutForPayment:controller.redirect.payment];
    
    if ([[UIApplication sharedApplication] keyWindow] == self.webController.view.superview) {
        [self.webController.view removeFromSuperview];
    }
    
    id data;
    
    if (paRes) {
        NSDictionary *dictionary = @{@"threeDSecureResponse": @{@"pares":paRes}};
        data = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self.endpointManager urlForResumePaymentWithInstallationID:self.credentials.installationID transactionID:transID]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0f];
    
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    [request setHTTPMethod:@"POST"];
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.credentials.token] forHTTPHeaderField:@"Authorization"];
    
    [request setHTTPBody:data];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSInteger statusCode = ((NSHTTPURLResponse*)response).statusCode;
        
        if (statusCode == 200) {
            
            NSError *invalidJSON;
            id json;
            if (data.length > 0) {
                json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
            }
            
            if (invalidJSON) {
                [self completePayment:controller.redirect.payment onMainThreadWithOutcome:nil withError:[PPOErrorManager errorForCode:PPOErrorServerFailure]];
                return;
            }
            
            PPOOutcome *outcome;
            if (json) {
                outcome = [[PPOOutcome alloc] initWithData:json];
            }
            
            if (outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == NO) {
                PPOErrorCode code = [PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue];
                [self completePayment:controller.redirect.payment onMainThreadWithOutcome:outcome withError:[PPOErrorManager errorForCode:code]];
            } else if (outcome.isSuccessful.boolValue == YES) {
                [self completePayment:controller.redirect.payment onMainThreadWithOutcome:outcome withError:nil];
            } else {
                [self completePayment:controller.redirect.payment onMainThreadWithOutcome:outcome withError:[PPOErrorManager errorForCode:PPOErrorUnknown]];
            }
            
        } else {
            [self completePayment:controller.redirect.payment onMainThreadWithOutcome:nil withError:[PPOErrorManager errorForCode:PPOErrorUnknown]];
        }
        
    }];
    
    [task resume];
    
}

-(void)webViewControllerDelayShowTimeoutExpired:(PPOWebViewController *)controller {
    if (!_preventShowWebView) {
        [PPOPaymentTrackingManager stopTimeoutForPayment:controller.redirect.payment];
        [self.webController.view removeFromSuperview];
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:self.webController];
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:navCon animated:YES completion:nil];
    }
}

-(void)webViewControllerSessionTimeoutExpired:(PPOWebViewController *)webController {
    [self handleError:[PPOErrorManager errorForCode:PPOErrorThreeDSecureTimedOut]
        webController:webController];
}

-(void)webViewController:(PPOWebViewController *)webController failedWithError:(NSError *)error {
    [self handleError:error
        webController:webController];
}

-(void)webViewControllerUserCancelled:(PPOWebViewController *)webController {
    [self handleError:[PPOErrorManager errorForCode:PPOErrorUserCancelled]
        webController:webController];
}

-(void)handleError:(NSError *)error webController:(PPOWebViewController *)webController {
    _preventShowWebView = YES;
    [self completePayment:webController.redirect.payment onMainThreadWithOutcome:nil withError:error];
}

-(void)completePayment:(PPOPayment*)payment onMainThreadWithOutcome:(PPOOutcome*)outcome withError:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [PPOPaymentTrackingManager removePayment:payment];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        //Depending on the delay show and session timeout timers, we may be currently showing the webview, or not.
        //Thus this check is essential.
        id controller = [[UIApplication sharedApplication] keyWindow].rootViewController.presentedViewController;
        if (controller && controller == self.webController.navigationController) {
            if (!_isDismissingWebView) {
                _isDismissingWebView = YES;
                [[[UIApplication sharedApplication] keyWindow].rootViewController dismissViewControllerAnimated:YES completion:^{
                    _isDismissingWebView = NO;
                    self.outcomeHandler(outcome, error);
                    _preventShowWebView = NO;
                }];
            }
        } else {
            self.outcomeHandler(outcome, error);
            _preventShowWebView = NO;
        }
    });
}

@end
