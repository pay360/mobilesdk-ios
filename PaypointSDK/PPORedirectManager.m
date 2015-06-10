//
//  PPOWebFormDelegate.m
//  Paypoint
//
//  Created by Robert Nash on 01/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPORedirectManager.h"
#import "PPOWebViewController.h"
#import "PPORedirect.h"
#import "PPOPaymentTrackingManager.h"
#import "PPOPaymentEndpointManager.h"
#import "PPOCredentials.h"
#import "PPOPayment.h"
#import "PPOSDKConstants.h"
#import "PPOURLRequestManager.h"
#import "ThreeDSecureDelegate.h"

@interface PPORedirectManager ()
@property (nonatomic, copy) void(^completion)(PPOOutcome *);
@property (nonatomic, strong) PPORedirect *redirect;
@property (nonatomic, strong) PPOWebViewController *webController;
@property (nonatomic, strong) PPOPaymentEndpointManager *endpointManager;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) ThreeDSecureDelegate *threeDSecureDelegate;
@end

@implementation PPORedirectManager

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
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Attempted to perform abort sequence, but it has been deliberately cleared.");
        }
        
    } forPayment:self.redirect.payment];
    
    self.threeDSecureDelegate = [[ThreeDSecureDelegate alloc] initWithSession:self.session
                                                                 withRedirect:redirect
                                                          withEndpointManager:self.endpointManager
                                                               withCompletion:self.completion];
    
    self.webController = [[PPOWebViewController alloc] initWithRedirect:redirect
                                                           withDelegate:self.threeDSecureDelegate];
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    self.webController.view.frame = CGRectMake(-height, -width, width, height);
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.webController.view];
}

@end
