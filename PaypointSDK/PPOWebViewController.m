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
#import <MessageUI/MFMailComposeViewController.h>

@interface PPOWebViewController () <UIWebViewDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSTimer *sessionTimeoutTimer;
@property (nonatomic, strong) NSTimer *delayShowTimer;
@end

@implementation PPOWebViewController {
    BOOL _firstLoadDone;
    BOOL _userCancelled;
    BOOL _preventShow;
}

-(instancetype)initWithRedirect:(PPORedirect *)redirect withDelegate:(id<PPOWebViewControllerDelegate>)delegate {
    self = [super initWithNibName:NSStringFromClass([PPOWebViewController class]) bundle:[PPOResourcesManager resources]];
    if (self) {
        _redirect = redirect;
        _delegate = delegate;
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self.webView loadRequest:self.redirect.request];
    if (!self.redirect.delayTimeInterval) {
        [self delayShow:nil];
    }
    
    NSBundle *bundle = [PPOResourcesManager resources];
    NSString *title = [bundle localizedStringForKey:@"Cancel" value:nil table:nil];
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed:)];
    
    title = [bundle localizedStringForKey:@"Authentication" value:nil table:nil];
    
    self.navigationItem.title = title;
    self.navigationItem.leftBarButtonItem = button;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (_userCancelled) {
        return NO;
    }
    
    NSURL *url = request.URL;
    NSString *email = [self isEmail:url];
    
    if (email.length > 0) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ([MFMailComposeViewController canSendMail]) {
                
                MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
                
                controller.mailComposeDelegate = self;
                
                [controller setToRecipients:@[email]];
                
                if (controller) {

                    [self presentViewController:controller
                                       animated:YES
                                     completion:^{
                                     }];
                }
                
            } else {
                
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
            
        });
        
        return NO;
        
    }
    
    if (_firstLoadDone) {
        BOOL isGet = [request.HTTPMethod isEqualToString:@"GET"];
        if (isGet) {
            if ([[UIApplication sharedApplication] canOpenURL:request.URL]) {
                [[UIApplication sharedApplication] openURL:request.URL];
            }
            return NO;
        } else {
            
            return YES;
        }
    }
    
    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {

    if (_firstLoadDone == NO) {
        _firstLoadDone = YES;
    }
    
    if (_firstLoadDone && self.redirect.delayTimeInterval) {
        self.delayShowTimer = [NSTimer scheduledTimerWithTimeInterval:self.redirect.delayTimeInterval.doubleValue target:self selector:@selector(delayShow:) userInfo:nil repeats:NO];
    }
    
    if ([webView.request.URL isEqual:self.redirect.termURL]) {
        _preventShow = YES;
        NSString *string = [webView stringByEvaluatingJavaScriptFromString:@"get3DSDataAsString();"];
        id json;
        if ([string isKindOfClass:[NSString class]] && string.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
        }
        NSString *pares = [json objectForKey:THREE_D_SECURE_PARES_KEY];
        NSString *md = [json objectForKey:THREE_D_SECURE_MD_KEY];
        [self cancelTimers];
        if (
            (pares && [pares isKindOfClass:[NSString class]] && pares.length == 0) ||
            (md && [md isKindOfClass:[NSString class]] && md.length == 0) ||
            !pares ||
            !md
            ) {
            [self.delegate webViewController:self failedWithError:[PPOErrorManager errorForCode:PPOErrorProcessingThreeDSecure]];
        } else {
            [self.delegate webViewController:self completedWithPaRes:pares forTransactionWithID:self.redirect.transactionID];
        }
    } else if (!self.redirect.termURL) {
        [self.delegate webViewController:self failedWithError:[PPOErrorManager errorForCode:PPOErrorProcessingThreeDSecure]];
    }
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    //NSURL *url = [error.userInfo objectForKey:@"NSErrorFailingURLKey"];
    //NSString *email = [self isEmail:url];
    
    [self cancelTimers];
    [self.delegate webViewController:self failedWithError:error];
}

-(NSString *)isEmail:(NSURL*)url {
    
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
    [self cancelTimers];
    [self.delegate webViewControllerSessionTimeoutExpired:self];
}

-(void)delayShow:(NSTimer*)timer {
    [self.delayShowTimer invalidate];
    self.delayShowTimer = nil;
    if (_preventShow) {
        return;
    }
    _preventShow = YES;
    [self.delegate webViewControllerDelayShowTimeoutExpired:self];
    if (self.redirect.sessionTimeoutTimeInterval) {
        self.sessionTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.redirect.sessionTimeoutTimeInterval.doubleValue target:self selector:@selector(sessionTimedOut:) userInfo:nil repeats:NO];
    }
}

-(void)cancelButtonPressed:(UIBarButtonItem*)button {
    _userCancelled = YES;
    [self cancelTimers];
    [self.delegate webViewControllerUserCancelled:self];
}

-(void)cancelTimers {
    [self.sessionTimeoutTimer invalidate];
    self.sessionTimeoutTimer = nil;
    [self.delayShowTimer invalidate];
    self.delayShowTimer = nil;
}

#pragma mark - MFMailComposer

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
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
