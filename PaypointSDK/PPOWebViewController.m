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
@property (nonatomic) NSTimeInterval sessionTimeout;
@property (nonatomic, strong) NSTimer *delayShowTimer;
@end

@implementation PPOWebViewController {

    /*
     * The web view is loaded offscreen, and is presented once a timeout value has expired.
     * The timeout value is sometimes zero, deliberately, depending on if we receive said 
     * value from a network response.
     *
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
                   withDelegate:(id<ThreeDSecureProtocol>)delegate {
    
    self = [super initWithNibName:NSStringFromClass([PPOWebViewController class]) bundle:[PPOResourcesManager resources]];
    
    if (self) {
        _redirect = redirect;
        _delegate = delegate;
        _sessionTimeout = redirect.sessionTimeoutTimeInterval.doubleValue;
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
        
        [weakSelf.delegate threeDSecureController:weakSelf
                                  failedWithError:[PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorMasterSessionTimedOut]];
        
        return;
        
    } else {
        
        [PPOPaymentTrackingManager overrideTimeoutHandler:^{
            
            _abortSession = YES;
            
            [weakSelf cancelThreeDSecureRelatedTimers];
            
            _preventShow = YES;
            
            if (weakSelf.webView.isLoading) {
                
                if (PPO_DEBUG_MODE) {
                    NSLog(@"Stopping web view completing load");
                }
                
                [weakSelf.webView stopLoading];
            } else {
                
                if (PPO_DEBUG_MODE) {
                    NSLog(@"Preventing web view controller continuing with 3DSecure session");
                }
                
                [weakSelf.delegate threeDSecureController:weakSelf
                                          failedWithError:[PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorMasterSessionTimedOut]];
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
            
            [self stopThreeDSecureTimer];
            
            if (self.sessionTimeout > 0) {
                [self presentViewController:controller animated:YES completion:nil];
            } else {
                [self.delegate threeDSecureController:self
                                      failedWithError:[PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorMasterSessionTimedOut]];
            }
            
        }
        
    } else {
        
        [self stopThreeDSecureTimer];
        
        if (self.sessionTimeout > 0) {
            
            NSString *title = @"Configuration";
            NSString *message = @"Please configure an email account in the Settings App.";
            NSString *dismissButton = @"Dismiss";
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            __weak typeof(self) weakSelf = self;
            UIAlertAction *action = [UIAlertAction actionWithTitle:dismissButton
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction *action) {
                                                               [weakSelf dismissViewControllerAnimated:YES
                                                                                            completion:nil];
                                                           }];
            
            [alert addAction:action];
            
            [self presentViewController:alert animated:YES completion:nil];
            
        } else {
            [self.delegate threeDSecureController:self
                                  failedWithError:[PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorMasterSessionTimedOut]];
        }
        
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
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Preventing web view controller continuing with 3DSecure session");
        }
        
        [weakSelf.delegate threeDSecureController:weakSelf
                                  failedWithError:[PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorMasterSessionTimedOut]];
        
    } forPayment:self.redirect.payment];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (!_initialWebViewLoadComplete) {
        _initialWebViewLoadComplete = YES;
    }
    
    if (_initialWebViewLoadComplete && self.redirect.delayTimeInterval && !self.delayShowTimer && !_delayShowTimeoutExpired) {
        
        if (PPO_DEBUG_MODE) {
            NSString *message = (self.redirect.delayTimeInterval.integerValue == 1) ? @"second" : @"seconds";
            NSLog(@"Web view loaded so starting 'delay show webview' countdown with a starting value of %@ %@", self.redirect.delayTimeInterval, message);
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
        
        [self.delegate threeDSecureController:self
                              failedWithError:[PPOErrorManager buildErrorForPrivateErrorCode:PPOPrivateErrorProcessingThreeDSecure]];
        
    } else {
        
        [self.delegate threeDSecureController:self
                                acquiredPaRes:pares];
        
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
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Attempted to perform abort sequence, but it has been deliberately cleared.");
        }
        
    } forPayment:self.redirect.payment];
    
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    [self clearMasterSessionTimeoutHandler];
    
    //NSURL *url = [error.userInfo objectForKey:@"NSErrorFailingURLKey"];
    //NSString *email = [self extractEmail:url];
    
    NSError *e = error;
    
    if (e.code == NSURLErrorCancelled) {
        e = [PPOErrorManager buildErrorForPaymentErrorCode:PPOPaymentErrorMasterSessionTimedOut];
    }
    
    [self cancelThreeDSecureRelatedTimers];
    
    [self.delegate threeDSecureController:self failedWithError:e];
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

-(void)sessionTimeoutTimerFired:(NSTimer*)timer {
    
    self.sessionTimeout--;
    
    if (self.sessionTimeout <= 0) {
        
        [PPOPaymentTrackingManager removePayment:self.redirect.payment];
        
        [self cancelThreeDSecureRelatedTimers];
        
        [self.delegate threeDSecureControllerSessionTimeoutExpired:self];
        
    }
    
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
    [self.delegate threeDSecureControllerDelayShowTimeoutExpired:self];
    
    /*
     * At this point, start the 3DSecure session timeout.
     */
    if (self.redirect.sessionTimeoutTimeInterval && !self.sessionTimeoutTimer) {
        
        [self resumeThreeDSecureSessionTimer];
        
    } else if (PPO_DEBUG_MODE && !self.redirect.sessionTimeoutTimeInterval && !self.sessionTimeoutTimer) {
        
        NSLog(@"3DSecure session does not have a session timeout for payment with op ref: %@", self.redirect.payment.identifier);
        
    }
}

-(void)resumeThreeDSecureSessionTimer {
    
    if (self.sessionTimeout > 0 && !self.sessionTimeoutTimer) {
        self.sessionTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                    target:self
                                                                  selector:@selector(sessionTimeoutTimerFired:)
                                                                  userInfo:nil
                                                                   repeats:YES];
        
        if (PPO_DEBUG_MODE) {
            NSString *message = (self.sessionTimeout == 1) ? @"second" : @"seconds";
            NSLog(@"Resuming 3DSecure session timeout with %f %@ remaining", self.sessionTimeout, message);
        }
        
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
    [self.delegate threeDSecureControllerUserCancelled:self];
}

-(void)cancelThreeDSecureRelatedTimers {
    [self stopDelayShowTimer];
    [self stopThreeDSecureTimer];
}

-(void)stopDelayShowTimer {
    
    if (self.delayShowTimer != nil) {
        [self.delayShowTimer invalidate];
        self.delayShowTimer = nil;
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Stopping 'delay show webview' countdown");
        }
    }
    
}

-(void)stopThreeDSecureTimer {
    
    if (self.sessionTimeoutTimer != nil) {
        [self.sessionTimeoutTimer invalidate];
        self.sessionTimeoutTimer = nil;
        
        if (PPO_DEBUG_MODE) {
            NSLog(@"Stopping 'three d secure session' timer");
        }
    }
    
}

#pragma mark - MFMailComposer

-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result
                       error:(NSError *)error {
    
    __weak typeof(self) weakSelf = self;
    
    switch (result) {
            
        case MFMailComposeResultSaved: {
            [self dismissViewControllerAnimated:YES completion:^{
                NSString *title = @"Mail";
                NSString *message = @"Message Saved";
                NSString *dismissButton = @"Dismiss";
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *action = [UIAlertAction actionWithTitle:dismissButton
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction *action) {
                                                                   [weakSelf dismissViewControllerAnimated:YES
                                                                                                completion:^{
                                                                                                    [weakSelf resumeThreeDSecureSessionTimer];
                                                                                                }];
                                                               }];
                
                [alert addAction:action];
                
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
            break;
            
        case MFMailComposeResultSent: {
            [self dismissViewControllerAnimated:YES completion:^{
                NSString *title = @"Mail";
                NSString *message = @"Message Sent";
                NSString *dismissButton = @"Dismiss";
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *action = [UIAlertAction actionWithTitle:dismissButton
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction *action) {
                                                                   [weakSelf dismissViewControllerAnimated:YES
                                                                                                completion:^{
                                                                                                    [weakSelf resumeThreeDSecureSessionTimer];
                                                                                                }];
                                                               }];
                
                [alert addAction:action];
                
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
            break;
            
        default:
            [self dismissViewControllerAnimated:YES completion:^{
                [weakSelf resumeThreeDSecureSessionTimer];
            }];
            break;
    }
    
}

#pragma mark - ThreeDSecureControllerProtocol

@synthesize rootView = _rootView;
@synthesize rootNavigationController = _rootNavigationController;

-(UIView *)rootView {
    if (_rootView == nil) {
        _rootView = self.view;
    }
    return _rootView;
}

-(UINavigationController *)rootNavigationController {
    if (_rootNavigationController == nil) {
        _rootNavigationController = self.navigationController;
    }
    return _rootNavigationController;
}

@end
