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
#import "PPOSDKConstants.h"
#import "PPOURLRequestManager.h"

@interface PPOWebFormManager () <PPOWebViewControllerDelegate>
@property (nonatomic, copy) void(^completion)(PPOOutcome *);
@property (nonatomic, strong) PPORedirect *redirect;
@property (nonatomic, strong) PPOWebViewController *webController;
@property (nonatomic, strong) PPOPaymentEndpointManager *endpointManager;
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation PPOWebFormManager  {
    BOOL _preventShowWebView;
    BOOL _isDismissingWebView;
    BOOL _isPresentingWebView;
    BOOL _isPerformingWebViewEventFinish;
    BOOL _hasPerformedWebViewEventFinish;
}

-(instancetype)initWithRedirect:(PPORedirect *)redirect
                    withSession:(NSURLSession *)session
            withEndpointManager:(PPOPaymentEndpointManager *)endpointManager
                 withCompletion:(void (^)(PPOOutcome *))completion {
    
    self = [super init];
    if (self) {
        _completion = completion;
        _endpointManager = endpointManager;
        _session = session;
        _redirect = redirect;
    }
    return self;
}

-(void)startRedirect {
    if (self.redirect) {
        [self startRedirectWithRedirect:self.redirect];
    }
}

/*
 * Paypoint provide use with a 'delay show webview' timeout, which should count down to zero, before we show
 * the webview. The ACS may complete with a 'fast redirect'. The idea behind this is to avoid the ugly UI associated 
 * with an ACS page showing, when it doesn't necessarily have to.
 * The webview's delegate will still fire, even if the webview is not displayed on screen.
 */
-(void)startRedirectWithRedirect:(PPORedirect*)redirect {
    
    if (PPO_DEBUG_MODE) {
        NSLog(@"Loading redirect web view hidden for payment with op ref: %@", redirect.payment.identifier);
    }
    
    [PPOPaymentTrackingManager overrideTimeoutHandler:^{
        
        /*
         * Lets clear this handler so that the web view has time to present itself. The web view controller will pick 
         * the responsibility in it's 'viewDidLoad' callback.
         */
        
    } forPayment:self.redirect.payment];
    
    /*
     * The PPOWebViewControllerDelegate protocol is set as a 'required' protocol.
     * This class will handle those callbacks.
     */
    self.webController = [[PPOWebViewController alloc] initWithRedirect:redirect
                                                           withDelegate:self];
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    self.webController.view.frame = CGRectMake(-height, -width, width, height);
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.webController.view];
}

#pragma mark - PPOWebViewController Delegate

-(void)webViewController:(PPOWebViewController *)controller completedWithPaRes:(NSString *)paRes {
    
    if (PPO_DEBUG_MODE) {
        NSLog(@"Web view concluded for payment with op ref: %@", controller.redirect.payment.identifier);
    }
    
    id body;
    
    if (paRes) {
        NSDictionary *dictionary = @{@"threeDSecureResponse": @{@"pares":paRes}};
        body = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    }
    
    controller.redirect.threeDSecureResumeBody = body;
    
    [self performResumeForRedirect:controller.redirect];
}

-(void)performResumeForRedirect:(PPORedirect*)redirect {
    
    BOOL masterSessionTimedOut = [PPOPaymentTrackingManager masterSessionTimeoutHasExpiredForPayment:self.redirect.payment];
    
    if (PPO_DEBUG_MODE && !masterSessionTimedOut) {
        NSLog(@"Performing resume request for payment with op ref: %@", redirect.payment.identifier);
    } else if (PPO_DEBUG_MODE && masterSessionTimedOut) {
        NSLog(@"Not attempting resume request for payment with op ref: %@", redirect.payment.identifier);
    }
    
    if (masterSessionTimedOut) {
        
        [self completeRedirect:redirect
                   withOutcome:[[PPOOutcome alloc] initWithError:[PPOErrorManager errorForCode:PPOErrorMasterSessionTimedOut]]];
        
        return;
    }
    
    NSURL *url = [self.endpointManager urlForResumePaymentWithInstallationID:redirect.payment.credentials.installationID
                                                               transactionID:redirect.transactionID];
    
    NSURLRequest *request = [PPOURLRequestManager requestWithURL:url
                                                      withMethod:@"POST"
                                                     withTimeout:30.0f
                                                       withToken:redirect.payment.credentials.token
                                                        withBody:redirect.threeDSecureResumeBody
                                                forPaymentWithID:redirect.payment.identifier];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:[self resumeResponseHandlerForRedirect:redirect]];
    
    __weak typeof(task) weakTask = task;
    
    [PPOPaymentTrackingManager overrideTimeoutHandler:^{
        [weakTask cancel];
    } forPayment:self.redirect.payment];
    
    [PPOPaymentTrackingManager resumeTimeoutForPayment:self.redirect.payment];
    
    [task resume];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

-(void(^)(NSData *, NSURLResponse *, NSError *))resumeResponseHandlerForRedirect:(PPORedirect*)redirect {
    
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
        } else if (invalidJSON) {
            outcome = [[PPOOutcome alloc] initWithError:[PPOErrorManager errorForCode:PPOErrorServerFailure]];
        } else if (networkError) {
            outcome = [[PPOOutcome alloc] initWithError:networkError];
        } else {
            outcome = [[PPOOutcome alloc] initWithError:[PPOErrorManager errorForCode:[PPOErrorManager errorCodeForReasonCode:PPOErrorUnknown]]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf completeRedirect:redirect withOutcome:outcome];
        });
        
    };
}

/**
 * Once an ACS page is fully loaded, it will either perform a fast re-direct or display fields for user input.
 * A fast re-direct does not require user input and shows an ugly spinner for a while.
 * The 'delay show' mechanism is in place to anticipate a fast re-direct, based on statistical historic data,
 * and prevent the display of an ugly web page. The 'delay show' countdown value is passed to us via a network response.
 * We begin counting down with this value, once the ACS web page has loaded and started a three d secure
 * session (fast re-direct or otherwise).
 * It is therefore very possible that we count down to completetion and display a web view that does not require
 * user input, and this is understood and accepted. The countdown provided to us is a 'probably requires user input
 * after this much time has elapsed' kind of value.
 */
-(void)webViewControllerDelayShowTimeoutExpired:(PPOWebViewController *)controller {
    
    /*
     * We only want to present once, so if we are called twice in error, ignore.
     */
    if (!_preventShowWebView && (!_isPresentingWebView || !_isDismissingWebView)) {
        
        _preventShowWebView = YES;
        
        /*
         * We only suspend the master session timeout here, and not before the delay show timeout has expired.
         * If we have reached this point then it is likely user input is required on the web view. The 'three d secure session timeout' will
         * begin, which is a timeout value provided by the redirect response. Once it has expired, it will handle abort. If
         * three d secure completes without any errors, then we resume the master session timeout countdown downstream.
         */
        [PPOPaymentTrackingManager suspendTimeoutForPayment:controller.redirect.payment];
        
        [self.webController.view removeFromSuperview];
        
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:self.webController];
        
        /*
        * Presenting controllers like this or toying with the implementing developers view heirarchy,
        * without the implementing developer's knowledge of when and how, is risky.
        * A merchant App may have an interesting animation that won't know when to 
        * terminate or change e.g. the current pulsing Paypoint logo in the demo merchant App 
        * has no indication of when to change or cancel before or after the web view is presented/dismissed.
        * May be upsetting behaviour if the implementing developer is using an interactive transitioning
        * protocol to present/dismiss the payment scene or a UIPresentationController which is managed by a 
        * transitioning context (provided by the system).
        * The merchant App may have multiple child view controllers, which may work mostly independently of one another.
        * Not exposing the webview makes styling of the web view navigation bar or the presentation animation tricky
        * UIBarButtonItem text is in strings file in embedded resources bundle, for internationalisation
        * Paypoint are aware of these points and are happy to release and get feedback.
         */
        if (PPO_DEBUG_MODE) {
            NSLog(@"Showing web view for op ref: %@", controller.redirect.payment.identifier);
        }
        
        _isPresentingWebView = YES;
        
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:navCon
                                                                                       animated:YES
                                                                                     completion:^{
                                                                                         _isPresentingWebView = NO;
                                                                                     }];
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
    
    /*
     * Let's make sure the web view process is completely arrested.
     */
    _preventShowWebView = YES;
    
    NSError *e = error;
    
    if (!e) {
        e = [PPOErrorManager errorForCode:PPOErrorUnknown];
    }
    
    [self completeRedirect:webController.redirect
               withOutcome:[[PPOOutcome alloc] initWithError:e]];
    
}

-(void)completeRedirect:(PPORedirect*)redirect withOutcome:(PPOOutcome*)outcome {
    
    if (_isPerformingWebViewEventFinish) {
        return;
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    [self destroyWebViewWithOutcome:outcome];
    
}

-(void)destroyWebViewWithOutcome:(PPOOutcome*)outcome {
    
    if (_isPerformingWebViewEventFinish) {
        return;
    }
    
    id controller = [[UIApplication sharedApplication] keyWindow].rootViewController.presentedViewController;
    
    if (controller && controller == self.webController.navigationController) {
        
        if (!_isDismissingWebView && !_isPresentingWebView) {
            
            _isDismissingWebView = YES;
            
            [[[UIApplication sharedApplication] keyWindow].rootViewController dismissViewControllerAnimated:YES
                                                                                                 completion:[self performWebViewEventFinishResetWithOutcome:outcome]];
            
        } else {
            [self performWebViewEventFinishResetWithOutcome:outcome];
        }
        
    } else {
        
        [self performWebViewEventFinishResetWithOutcome:outcome]();
        
    }
    
}

-(void(^)(void))performWebViewEventFinishResetWithOutcome:(PPOOutcome*)outcome {
    
    __weak typeof(self) weakSelf = self;
    
    return ^ {
        
        if (_isPerformingWebViewEventFinish) {
            return;
        }
        
        _isPerformingWebViewEventFinish = YES;
        
        _isDismissingWebView = NO;
        
        if ([[UIApplication sharedApplication] keyWindow] == weakSelf.webController.view.superview) {
            
            if (PPO_DEBUG_MODE) {
                NSLog(@"Removing web view for payment with op ref: %@", weakSelf.redirect.payment.identifier);
            }
            
            [weakSelf.webController.view removeFromSuperview];
            
            weakSelf.webController = nil;
            
        }
        
        if (outcome) {
            weakSelf.completion(outcome);
        }
        
        _preventShowWebView = NO;
    };
    
}

@end
