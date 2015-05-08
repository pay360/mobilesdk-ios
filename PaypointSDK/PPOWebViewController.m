//
//  PPOWebViewController.m
//  Paypoint
//
//  Created by Robert Nash on 26/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOWebViewController.h"

@interface PPOWebViewController () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSTimer *sessionTimeoutTimer;
@property (nonatomic, strong) NSTimer *delayShowTimer;
@end

@implementation PPOWebViewController {
    BOOL _firstLoad;
    BOOL _testingFastAuth;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    _testingFastAuth = NO;
    
    [self.webView loadRequest:self.request];
    if (!self.delayTimeInterval && !_testingFastAuth) {
        [self delayShow:nil];
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_testingFastAuth) {
        [self testingAutomaticAuthentication];
    }
}

-(void)testingAutomaticAuthentication {
    [self performSelector:@selector(trigger) withObject:nil afterDelay:2];
}

-(void)trigger {
    [self cancelTimers];
    [self.delegate webViewController:self completedWithPaRes:@"dsfds" forTransactionWithID:@"dsfsd"];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    NSString *email = [self isEmail:url];
    if (email.length > 0) {
#warning trigger mail client here. session timeout will still fire and this will dismiss any modal controller currently showing
        return NO;
    }
    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {

    if (_firstLoad == NO) {
        _firstLoad = YES;
    }
    
    if (_firstLoad && self.delayTimeInterval) {
        self.delayShowTimer = [NSTimer scheduledTimerWithTimeInterval:self.delayTimeInterval.doubleValue target:self selector:@selector(delayShow:) userInfo:nil repeats:NO];
    }
    
    NSString *urlString = webView.request.URL.absoluteString;
    if ([urlString isEqualToString:self.termURLString]) {
        NSString *string = [webView stringByEvaluatingJavaScriptFromString:@"get3DSData();"];
        id json = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
        NSString *pares = [json objectForKey:@"PaRes"];
        NSString *md = [json objectForKey:@"MD"];
        [self cancelTimers];
        [self.delegate webViewController:self completedWithPaRes:pares forTransactionWithID:md];
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
    [self.delegate webViewControllerDelayShowTimeoutExpired:self];
    if (self.sessionTimeoutTimeInterval) {
        self.sessionTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.sessionTimeoutTimeInterval.doubleValue target:self selector:@selector(sessionTimedOut:) userInfo:nil repeats:NO];
    }
}

-(void)cancelButtonPressed:(UIBarButtonItem*)button {
    [self cancelTimers];
    [self.delegate webViewControllerUserCancelled:self];
}

-(void)cancelTimers {
    [self.sessionTimeoutTimer invalidate];
    self.sessionTimeoutTimer = nil;
    [self.delayShowTimer invalidate];
    self.delayShowTimer = nil;
}

@end
