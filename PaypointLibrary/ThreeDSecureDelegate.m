//
//  PPOWebViewControllerDelegate.m
//  Paypoint
//
//  Created by Robert Nash on 08/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "ThreeDSecureDelegate.h"
#import "PPOSDKConstants.h"
#import "PPOWebViewController.h"
#import "PPOPayment.h"
#import "PPOPaymentTrackingManager.h"
#import "PPORedirect.h"
#import "PPOOutcomeBuilder.h"
#import "PPOErrorManager.h"
#import "PPOPaymentEndpointManager.h"
#import "PPOCredentials.h"
#import "PPOURLRequestManager.h"

@interface ThreeDSecureDelegate ()
@property (nonatomic, strong) PPORedirect *redirect;
@property (nonatomic, strong) PPOPaymentEndpointManager *endpointManager;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) void(^completion)(PPOOutcome*);
@end

/*
 * This is not exactly a convential way to use a webView and I have noticed some strange
 * behaviour sometimes; such as webViewDidFinishLoad: firing once offscreen, then once after
 * viewDidAppear: for the same request. Thus setting state flags here for peace of mind.
 */
@implementation ThreeDSecureDelegate {
    BOOL _preventShowWebView;
    BOOL _isDismissingWebView;
    BOOL _isPresentingWebView;
    BOOL _isPerformingWebViewEventFinish;
}

-(instancetype)initWithSession:(NSURLSession*)session
                  withRedirect:(PPORedirect *)redirect
           withEndpointManager:(PPOPaymentEndpointManager *)manager
                withCompletion:(void(^)(PPOOutcome*))completion {
    self = [super init];
    if (self) {
        _redirect = redirect;
        _endpointManager = manager;
        _session = session;
        _completion = completion;
    }
    return self;
}

-(void)threeDSecureController:(id<ThreeDSecureControllerProtocol>)controller
                acquiredPaRes:(NSString *)paRes {
    
    if (PPO_DEBUG_MODE) {
        NSLog(@"Building resume body for payment with op ref: %@", controller.redirect.payment.identifier);
    }
    
    id body;
    
    if (paRes) {
        NSDictionary *dictionary = @{@"threeDSecureResponse": @{@"pares":paRes}};
        body = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    }
    
    controller.redirect.threeDSecureResumeBody = body;
    
    [self performResumeForRedirect:controller.redirect
                     forController:controller];
    
}

-(void)performResumeForRedirect:(PPORedirect*)redirect
                  forController:(id<ThreeDSecureControllerProtocol>)controller {
    
    BOOL masterSessionTimedOut = [PPOPaymentTrackingManager masterSessionTimeoutHasExpiredForPayment:self.redirect.payment];
    
    if (PPO_DEBUG_MODE && !masterSessionTimedOut) {
        NSLog(@"Performing resume request for payment with op ref: %@", redirect.payment.identifier);
    } else if (PPO_DEBUG_MODE && masterSessionTimedOut) {
        NSLog(@"Not attempting resume request for payment with op ref: %@", redirect.payment.identifier);
    }
    
    if (masterSessionTimedOut) {
        
        PPOOutcome *outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                                       withError:[PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorMasterSessionTimedOut]
                                                      forPayment:redirect.payment];
        
        [self completeRedirect:redirect
                   withOutcome:outcome
                 forController:controller];
        
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
    
    id completionHandler = [self resumeResponseHandlerForRedirect:redirect
                                                    forController:controller];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:completionHandler];
    
    __weak typeof(task) weakTask = task;
    
    [PPOPaymentTrackingManager overrideTimeoutHandler:^{
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Cancelling resume request");
        }
        
        [weakTask cancel];
        
    } forPayment:self.redirect.payment];
    
    [PPOPaymentTrackingManager resumeTimeoutForPayment:self.redirect.payment];
    
    [task resume];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

-(void(^)(NSData *, NSURLResponse *, NSError *))resumeResponseHandlerForRedirect:(PPORedirect*)redirect
                                                                   forController:(id<ThreeDSecureControllerProtocol>)controller {
    
    __weak typeof(self) weakSelf = self;
    
    return ^ (NSData *data, NSURLResponse *response, NSError *networkError) {
        
        NSError *invalidJSON;
        
        id json;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        PPOOutcome *outcome;
        
        if (json) {
            outcome = [PPOOutcomeBuilder outcomeWithData:json
                                               withError:nil
                                              forPayment:redirect.payment];
        } else if (invalidJSON) {
            outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                               withError:[PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorServerFailure]
                                              forPayment:redirect.payment];
        } else if (networkError) {
            outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                               withError:networkError
                                              forPayment:redirect.payment];
        } else {
            outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                               withError:[PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorUnexpected]
                                              forPayment:redirect.payment];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf completeRedirect:redirect
                           withOutcome:outcome
                         forController:controller];
        });
        
    };
}

/**
 * Once an ACS page is fully loaded, it will either perform a fast re-direct or display entry fields for user input.
 * A fast re-direct does not require user input and shows an ugly spinner for a while.
 * The 'delay show' countdown value is passed to us via a network response.
 * The countdown provided to us is a 'probably requires user input
 * after this much time has elapsed so present the web view now' kind of value.
 */

-(void)threeDSecureControllerDelayShowTimeoutExpired:(id<ThreeDSecureControllerProtocol>)controller {
    /*
     * We only want to present once, so if we are called twice in error, ignore.
     */
    if (!_preventShowWebView && (!_isPresentingWebView || !_isDismissingWebView)) {
        
        _preventShowWebView = YES;
        
        /*
         * We only suspend the master session timeout here, and not before the delay show timeout has expired.
         * If we have reached this point then it is likely that user input is required on the web view. The 'three d secure session timeout' will
         * begin, which is a timeout value provided by the redirect response. Once it has expired, it will handle abort. If
         * three d secure completes without any errors, then we resume the master session timeout countdown downstream.
         */
        [PPOPaymentTrackingManager suspendTimeoutForPayment:controller.redirect.payment];
        
        [controller.rootView removeFromSuperview];
        
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:(UIViewController*)controller];
        
        /*
         * Presenting controllers like this or toying with the implementing developers view heirarchy,
         * without the implementing developer's knowledge of when and how, is risky.
         *
         * 1) Conforming to any of the adaptive api's will be impossible.
         *
         * 2) NavBar customisations or customisation of the web view controller presentation animation, will be tricky, if not impossible.
         *
         * 3) May be upsetting behaviour if the implementing developer is conforming to an animated transitioning
         *    protocol or using a UIPresentationController.
         *
         * 4) There may be an animation that won't know when to terminate or change before the web view is shown
         *    e.g. the current pulsing Paypoint logo in the demo merchant App has no idea and just keeps pulsing.
         *
         * Paypoint are aware of these points and they are happy to release to customers and get feedback from them first.
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

-(void)threeDSecureControllerSessionTimeoutExpired:(id<ThreeDSecureControllerProtocol>)controller {
    [self handleError:[PPOErrorManager buildErrorForPrivateErrorCode:PPOPrivateErrorThreeDSecureTimedOut]
        forController:controller];
}

-(void)threeDSecureController:(id<ThreeDSecureControllerProtocol>)controller failedWithError:(NSError *)error {
    [self handleError:error
        forController:controller];
}

-(void)threeDSecureControllerUserCancelled:(id<ThreeDSecureControllerProtocol>)controller {
    [self handleError:[PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorUserCancelledThreeDSecure]
        forController:controller];
}

-(void)handleError:(NSError *)error forController:(id<ThreeDSecureControllerProtocol>)controller {
    
    /*
     * Let's make sure the web view process is completely arrested.
     */
    _preventShowWebView = YES;
    
    NSError *e = error;
    
    if (!e) {
        e = [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorUnexpected];
    }
    
    PPOOutcome *outcome = [PPOOutcomeBuilder outcomeWithData:nil
                                                   withError:e
                                                  forPayment:controller.redirect.payment];
    
    [self completeRedirect:controller.redirect
               withOutcome:outcome
             forController:controller];
    
}

-(void)completeRedirect:(PPORedirect*)redirect
            withOutcome:(PPOOutcome*)outcome
          forController:(id<ThreeDSecureControllerProtocol>)controller {
    
    if (_isPerformingWebViewEventFinish) {
        return;
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    [self destroyWebViewController:controller
                        forOutcome:outcome];
    
}

-(void)destroyWebViewController:(id<ThreeDSecureControllerProtocol>)controller
                     forOutcome:(PPOOutcome*)outcome {
    
    if (_isPerformingWebViewEventFinish) {
        return;
    }
    
    id presentedController = [[UIApplication sharedApplication] keyWindow].rootViewController.presentedViewController;
    
    if (presentedController && presentedController == controller.rootNavigationController) {
        
        if (!_isDismissingWebView && !_isPresentingWebView) {
            
            _isDismissingWebView = YES;
            
            id completionHandler = [self performWebViewController:controller
                                      eventFinishResetWithOutcome:outcome];
            
            [[[UIApplication sharedApplication] keyWindow].rootViewController dismissViewControllerAnimated:YES
                                                                                                 completion:completionHandler];
            
        } else {
            [self performWebViewController:controller
               eventFinishResetWithOutcome:outcome]();
        }
        
    } else {
        
        [self performWebViewController:controller
           eventFinishResetWithOutcome:outcome]();
        
    }
    
}

-(void(^)(void))performWebViewController:(id<ThreeDSecureControllerProtocol>)controller
             eventFinishResetWithOutcome:(PPOOutcome*)outcome {
    
    __weak typeof(self) weakSelf = self;
    
    return ^ {
        
        if (_isPerformingWebViewEventFinish) {
            return;
        }
        
        _isPerformingWebViewEventFinish = YES;
        
        _isDismissingWebView = NO;
                
        if ([[UIApplication sharedApplication] keyWindow] == controller.rootView.superview) {
            
            if (PPO_DEBUG_MODE) {
                NSLog(@"Removing web view for payment with op ref: %@", weakSelf.redirect.payment.identifier);
            }
            
            [controller.rootView removeFromSuperview];
            
        }
        
        if (outcome) {
            weakSelf.completion(outcome);
        }
        
        _preventShowWebView = NO;
    };
    
}

@end
