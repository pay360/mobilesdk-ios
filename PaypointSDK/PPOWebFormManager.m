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
#import "PPOPayment.h"
#import "PPOURLRequestManager.h"

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

//Loading a webpage requires a webView, but we don't want to show a webview on screen during this time.
//The webview's delegate will still fire, even if the webview is not displayed on screen.
-(void)loadRedirect:(PPORedirect*)redirect {
    self.webController = [[PPOWebViewController alloc] initWithRedirect:redirect withDelegate:self];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    self.webController.view.frame = CGRectMake(-height, -width, width, height);
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.webController.view];
}

#pragma mark - PPOWebViewController

-(void)webViewController:(PPOWebViewController *)controller
      completedWithPaRes:(NSString *)paRes
    forTransactionWithID:(NSString *)transID {
    
    _preventShowWebView = YES;
    
    [PPOPaymentTrackingManager resumeTimeoutForPayment:controller.redirect.payment];
    
    if ([[UIApplication sharedApplication] keyWindow] == self.webController.view.superview) {
        [self.webController.view removeFromSuperview];
    }
    
    id body;
    
    if (paRes) {
        NSDictionary *dictionary = @{@"threeDSecureResponse": @{@"pares":paRes}};
        body = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    }
    
    NSURL *url = [self.endpointManager urlForResumePaymentWithInstallationID:self.credentials.installationID transactionID:transID];
    
    NSURLRequest *request = [PPOURLRequestManager requestWithURL:url
                                                      withMethod:@"POST"
                                                     withTimeout:30.0f
                                                       withToken:self.credentials.token
                                                        withBody:body
                                                forPaymentWithID:controller.redirect.payment.identifier];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:[self resumeResponseHandlerForPayment:controller.redirect.payment]];
    
    [task resume];
    
}

-(void(^)(NSData *, NSURLResponse *, NSError *))resumeResponseHandlerForPayment:(PPOPayment*)payment {
    
    __weak typeof(self) weakSelf = self;
    
    return ^ (NSData *data, NSURLResponse *response, NSError *networkError) {
        
        NSError *invalidJSON;
        
        id json;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        PPOOutcome *outcome;
        
        if (json) {
            outcome = [[PPOOutcome alloc] initWithData:json];
        }
        
        NSError *e;
        
        if (invalidJSON) {
            
            e = [PPOErrorManager errorForCode:PPOErrorServerFailure];
            
        } else if (outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == NO) {
            
            e = [PPOErrorManager errorForCode:[PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue]];
            
        } else if (outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == YES) {
            
            e = nil;
            
        } else if (networkError) {
            
            e = networkError;

        } else {
            
            e = [PPOErrorManager errorForCode:PPOErrorUnknown];
            
        }
        
        [PPOPaymentTrackingManager removePayment:payment];
        
        [weakSelf completePayment:payment onMainThreadWithOutcome:outcome withError:e];
    };
}

/**
 *  The delay show mechanism is in place to prevent the web view from presenting itself, when it begins to load.
 *  Once the delay expires, the web view is shown, regardless of it's loading state.
 *  This mechanism is used to show the webview, even when a time value is not provided i.e. timeout value = 0
 *  ensuring that this method is the only method that controls web view presentation.
 */
-(void)webViewControllerDelayShowTimeoutExpired:(PPOWebViewController *)controller {
    
    if (!_preventShowWebView) {
        
        [PPOPaymentTrackingManager suspendTimeoutForPayment:controller.redirect.payment];
        
        [self.webController.view removeFromSuperview];
        
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:self.webController];
        
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:navCon
                                                                                       animated:YES
                                                                                     completion:nil];
    }
    
}

-(void)webViewControllerSessionTimeoutExpired:(PPOWebViewController *)webController {
    [self handleError:[PPOErrorManager errorForCode:PPOErrorThreeDSecureTimedOut] webController:webController];
}

-(void)webViewController:(PPOWebViewController *)webController failedWithError:(NSError *)error {
    [self handleError:error webController:webController];
}

-(void)webViewControllerUserCancelled:(PPOWebViewController *)webController {
    [self handleError:[PPOErrorManager errorForCode:PPOErrorUserCancelled] webController:webController];
}

-(void)handleError:(NSError *)error webController:(PPOWebViewController *)webController {
    
    _preventShowWebView = YES;
    
    [PPOPaymentTrackingManager removePayment:webController.redirect.payment];
    
    [self completePayment:webController.redirect.payment onMainThreadWithOutcome:nil withError:error];
    
}

-(void)completePayment:(PPOPayment*)payment onMainThreadWithOutcome:(PPOOutcome*)outcome withError:(NSError*)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        //Depending on the delay show and session timeout timers, we may be currently showing the webview, or not.
        id controller = [[UIApplication sharedApplication] keyWindow].rootViewController.presentedViewController;
        
        if (controller && controller == self.webController.navigationController) {
            
            if (!_isDismissingWebView) {
                
                _isDismissingWebView = YES;
                
                [[[UIApplication sharedApplication] keyWindow].rootViewController dismissViewControllerAnimated:YES completion:^{
                    
                    _isDismissingWebView = NO;
                    
                    if (!error) {
                        [PPOPaymentTrackingManager resumeTimeoutForPayment:payment];
                    }
                    
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
