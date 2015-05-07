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
    [self.sessionTimeoutTimer invalidate];
    self.sessionTimeoutTimer = nil;
    [self.delayShowTimer invalidate];
    self.delayShowTimer = nil;
    [self.delegate webViewController:self completedWithPaRes:@"dsfds" forTransactionWithID:@"dsfsd"];
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
        [self.delegate webViewController:self completedWithPaRes:pares forTransactionWithID:md];
    }
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    //NSString *email = [self isEmail:error];
    
    [self.sessionTimeoutTimer invalidate];
    self.sessionTimeoutTimer = nil;
    [self.delayShowTimer invalidate];
    self.delayShowTimer = nil;
    [self.delegate webViewController:self failedWithError:error];
}

-(NSString *)isEmail:(NSError*)error {
    
    NSString *email;
    
    NSURL *url = [error.userInfo objectForKey:@"NSErrorFailingURLKey"];
    if ([url isKindOfClass:[NSURL class]]) {
        NSString *string = url.absoluteString;
        NSArray *components = [string componentsSeparatedByString:@":"];
        string = components.firstObject;
        if ([string isEqualToString:@"mailto"]) {
            //trigger native email client
            NSLog(@"mailto");
        }
        email = components.lastObject;
    }
    
    return email;
}

-(void)sessionTimedOut:(NSTimer*)timer {
    [self.sessionTimeoutTimer invalidate];
    self.sessionTimeoutTimer = nil;
    [self.delayShowTimer invalidate];
    self.delayShowTimer = nil;
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
    [self.sessionTimeoutTimer invalidate];
    self.sessionTimeoutTimer = nil;
    [self.delayShowTimer invalidate];
    self.delayShowTimer = nil;
    [self.delegate webViewControllerUserCancelled:self];
}

@end
