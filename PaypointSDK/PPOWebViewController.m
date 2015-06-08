//
//  PPOWebViewController.m
//  Paypoint
//
//  Created by Robert Nash on 26/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOWebViewController.h"
#import "PPOResourcesManager.h"
#import "PPOErrorManager.h"
#import "PPOSDKConstants.h"
#import "PPOPayment.h"
#import "PPOPaymentTrackingManager.h"
#import <MessageUI/MFMailComposeViewController.h>

@interface PPOWebViewController () <UIWebViewDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSTimer *sessionTimeoutTimer;
@property (nonatomic, strong) NSTimer *delayShowTimer;
@end

@implementation PPOWebViewController {
    
    /*
     * The web view is loaded offscreen, and is presented once a timeout value has expired.
     * The timeout value is sometimes zero, deliberately, depending on if we receive said 
     * value from a network response.
     * This is not exactly a convential way to use a webView and I have noticed some strange 
     * behaviour sometimes; such as webViewDidFinishLoad: firing once offscreen, then once after 
     * viewDidAppear: for the same request. Thus setting state flags here for peace of mind.
     */
    BOOL _initialWebViewLoadComplete;
    BOOL _userCancelled;
    BOOL _preventShow;
    BOOL _delayShowTimeoutExpired;
    BOOL _masterSessionTimeoutExpired;
    BOOL _abortSession; //The master timeout session timeout handler is about to action.
}

-(instancetype)initWithRedirect:(PPORedirect *)redirect
                   withDelegate:(id<PPOWebViewControllerDelegate>)delegate {
    
    self = [super initWithNibName:NSStringFromClass([PPOWebViewController class]) bundle:[PPOResourcesManager resources]];
    
    if (self) {
        _redirect = redirect;
        _delegate = delegate;
    }
    
    return self;
}

-(void)viewDidLoad {
    
    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    
    /*
     * The parent web form manager class that presented us, cleared the session timeout handler so that we have time to animate onscreen.
     * Therefore, we are now responsible for responding to a master session timeout event, should it have already fired by now.
     * If it hasn't, then lets assign a new timeout handler.
     */
    if ([PPOPaymentTrackingManager masterSessionTimeoutHasExpiredForPayment:self.redirect.payment]) {
        
        _abortSession = YES;
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Aborting web view session commencement");
        }
        
        [weakSelf.delegate webViewController:weakSelf
                             failedWithError:[PPOErrorManager errorForCode:PPOErrorMasterSessionTimedOut]];
        
        return;
        
    } else {
        
        [PPOPaymentTrackingManager overrideTimeoutHandler:^{
            
            _abortSession = YES;
            
            [weakSelf cancelThreeDSecureRelatedTimers];
            
            _preventShow = YES;
            
            if (weakSelf.webView.isLoading) {
                [weakSelf.webView stopLoading];
            } else {
                [weakSelf.delegate webViewController:weakSelf
                                     failedWithError:[PPOErrorManager errorForCode:PPOErrorMasterSessionTimedOut]];
            }
            
        } forPayment:self.redirect.payment];
        
    }
    
    if (_abortSession) {
        return;
    }
        
    [self.webView loadRequest:self.redirect.request];
    
    if (!self.redirect.delayTimeInterval) {
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Delay show timeout not provided in redirect.");
        }
        
        /*
         * No timeout provided, so fire the conclusion for it immediately.
         */
        [self delayShowTimeoutExpired:nil];
        
    }
    
    NSBundle *bundle = [PPOResourcesManager resources];
    
    NSString *title;
    
    title = [bundle localizedStringForKey:@"Cancel"
                                    value:nil
                                    table:nil];
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:title
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(cancelButtonPressed:)];
    
    title = [bundle localizedStringForKey:@"Authentication"
                                    value:nil
                                    table:nil];
    
    self.navigationItem.title = title;
    
    self.navigationItem.leftBarButtonItem = button;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (_userCancelled || _abortSession) {
        return NO;
    }
    
    NSURL *url = request.URL;
    
    NSString *email = [self extractEmail:url];
    
    if (email && [email isKindOfClass:[NSString class]] && email.length > 0) {
        
#warning are we on the main queue here ?
        
        [self showMailComposerForToReceipient:email];
        
        return NO;
        
    }
    
    if (_initialWebViewLoadComplete) {
        
        /*
         * We do not want to navigate away from the 3DSecure iframe.
         * So open any links like this in an external browser.
         */
        if ([request.HTTPMethod isEqualToString:@"GET"]) {
            
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
            
            return NO;
            
        } else {
            
            return YES;
        }
    }
    
    return YES;
}

-(void)showMailComposerForToReceipient:(NSString*)receipientEmail {
    
    if ([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        
        controller.mailComposeDelegate = self;
        
        [controller setToRecipients:@[receipientEmail]];
        
        if (controller) {
            
            [self presentViewController:controller
                               animated:YES
                             completion:^{
                             }];
        }
        
    } else {
        
#warning handle master session or three d secure session timeouts for event where this is on screen
        
        NSString *title = @"Configuration";
        NSString *message = @"Please configure an email account in the Settings App.";
        NSString *dismissButton = @"Dismiss";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:dismissButton
                                                  otherButtonTitles:nil, nil];
        
        [alertView show];
        
    }
    
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    
    if (_abortSession) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    [PPOPaymentTrackingManager overrideTimeoutHandler:^{
        
        _abortSession = YES;
        
        [weakSelf.delegate webViewController:weakSelf
                             failedWithError:[PPOErrorManager errorForCode:PPOErrorMasterSessionTimedOut]];
        
    } forPayment:self.redirect.payment];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (!_initialWebViewLoadComplete) {
        _initialWebViewLoadComplete = YES;
    }
    
    if (_initialWebViewLoadComplete && self.redirect.delayTimeInterval && !self.delayShowTimer && !_delayShowTimeoutExpired) {
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Delay show countdown found with value %@ seconds", self.redirect.delayTimeInterval);
            NSLog(@"Web view loaded. Starting delay show countdown now.");
        }
        
        self.delayShowTimer = [NSTimer scheduledTimerWithTimeInterval:self.redirect.delayTimeInterval.doubleValue
                                                               target:self
                                                             selector:@selector(delayShowTimeoutExpired:)
                                                             userInfo:nil
                                                              repeats:NO];
        
    }
    
    if ([webView.request.URL isEqual:self.redirect.termURL]) {
        
        [self extractThreeDSecureData:webView];
        
    }
    
}

-(void)extractThreeDSecureData:(UIWebView*)webView {
    
    if (_abortSession) {
        return;
    }
    
    [self clearMasterSessionTimeoutHandler];
    
    _preventShow = YES;
    
    [self cancelThreeDSecureRelatedTimers];
    
    NSString *string = [webView stringByEvaluatingJavaScriptFromString:@"get3DSDataAsString();"];
    
    id json;
    
    if ([string isKindOfClass:[NSString class]] && string.length > 0) {
        json = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    }
    
    NSString *pares = [json objectForKey:THREE_D_SECURE_PARES_KEY];
    NSString *md = [json objectForKey:THREE_D_SECURE_MD_KEY];
    
    BOOL problemWithParesOrMD = !pares || !md || ![pares isKindOfClass:[NSString class]] || pares.length == 0 || ![md isKindOfClass:[NSString class]] || md.length == 0;
    
    if (problemWithParesOrMD) {
        
        [self.delegate webViewController:self
                         failedWithError:[PPOErrorManager errorForCode:PPOErrorProcessingThreeDSecure]];
        
    } else {
        
        [self.delegate webViewController:self
                      completedWithPaRes:pares];
        
    }
    
}

-(void)clearMasterSessionTimeoutHandler {
    
    /*
     * Call this if we have a conclusion to 3DSecure.
     * Let's reset the UI before we handle the event of a master
     * session timeout, should there be one. The delegate for this controller will take responsbility
     * for resetting it (and will check if it has not already fired).
     */
    [PPOPaymentTrackingManager overrideTimeoutHandler:^{
        
    } forPayment:self.redirect.payment];
    
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    [self clearMasterSessionTimeoutHandler];
    
    //NSURL *url = [error.userInfo objectForKey:@"NSErrorFailingURLKey"];
    //NSString *email = [self extractEmail:url];
    
    NSError *e = error;
    
    if (e.code == NSURLErrorCancelled) {
        e = [PPOErrorManager errorForCode:PPOErrorMasterSessionTimedOut];
    }
    
    [self cancelThreeDSecureRelatedTimers];
    
    [self.delegate webViewController:self failedWithError:e];
}

-(NSString *)extractEmail:(NSURL*)url {
    
    NSString *email;
    
    if ([url isKindOfClass:[NSURL class]]) {
        NSString *string = url.absoluteString;
        NSArray *components = [string componentsSeparatedByString:@":"];
        string = components.firstObject;
        if (![string isEqualToString:@"mailto"]) {
            return nil;
        }
        email = components.lastObject;
    }
    
    return email;
}

-(void)sessionTimedOut:(NSTimer*)timer {
    
    [PPOPaymentTrackingManager removePayment:self.redirect.payment];
    
    [self cancelThreeDSecureRelatedTimers];
    
    [self.delegate webViewControllerSessionTimeoutExpired:self];
}

-(void)delayShowTimeoutExpired:(NSTimer*)timer {
    
    [timer invalidate];
    
    _delayShowTimeoutExpired = YES;
    
    self.delayShowTimer = nil;
    
    if (_preventShow || _abortSession) {
        return;
    }

    _preventShow = YES;
    
    /*
     * The master timeout and the 3DSecure session timeout should be mutually exclusive.
     * The implementing developers master timeout session is suspended by our delegate, here.
     * Our delegate is our parent and presents us on screen here.
     */
    [self.delegate webViewControllerDelayShowTimeoutExpired:self];
    
    /*
     * At this point, start the 3DSecure session timeout.
     */
    if (self.redirect.sessionTimeoutTimeInterval && !self.sessionTimeoutTimer) {
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Will end 3DSecure session in %@ seconds", self.redirect.sessionTimeoutTimeInterval);
        }
        
        self.sessionTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.redirect.sessionTimeoutTimeInterval.doubleValue
                                                                    target:self
                                                                  selector:@selector(sessionTimedOut:)
                                                                  userInfo:nil
                                                                   repeats:NO];
        
    } else if (PPO_DEBUG_MODE && !self.redirect.sessionTimeoutTimeInterval && !self.sessionTimeoutTimer) {
        
        NSLog(@"3DSecure session does not have a session timeout for payment with op ref: %@", self.redirect.payment.identifier);
        
    }
}

-(void)cancelButtonPressed:(UIBarButtonItem*)button {
    
    if (_abortSession) {
        return;
    }
    
    if (PPO_DEBUG_MODE) {
        NSLog(@"Cancel button pressed");
    }
    
    _userCancelled = YES;
    [self cancelThreeDSecureRelatedTimers];
    [self.delegate webViewControllerUserCancelled:self];
}

-(void)cancelThreeDSecureRelatedTimers {
    
    if (PPO_DEBUG_MODE) {
        NSLog(@"Stopping all timers associated with 3DSecure session");
    }
    
    [self.sessionTimeoutTimer invalidate];
    self.sessionTimeoutTimer = nil;
    [self.delayShowTimer invalidate];
    self.delayShowTimer = nil;
}

#pragma mark - MFMailComposer

-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result
                       error:(NSError *)error {
    
    switch (result) {
            
        case MFMailComposeResultSaved: {
            [self dismissViewControllerAnimated:YES completion:^{
                NSString *title = @"Mail";
                NSString *message = @"Message Saved";
                NSString *dismissButton = @"Dismiss";
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                                    message:message
                                                                   delegate:self
                                                          cancelButtonTitle:dismissButton
                                                          otherButtonTitles:nil, nil];
                
                [alertView show];
            }];
        }
            break;
            
        case MFMailComposeResultSent: {
            [self dismissViewControllerAnimated:YES completion:^{
                NSString *title = @"Mail";
                NSString *message = @"Message Sent";
                NSString *dismissButton = @"Dismiss";
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                                    message:message
                                                                   delegate:self
                                                          cancelButtonTitle:dismissButton
                                                          otherButtonTitles:nil, nil];
                
                [alertView show];
            }];
        }
            break;
            
        default:
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
    }
}

@end
