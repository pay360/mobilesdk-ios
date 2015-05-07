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
@end

@implementation PPOWebViewController {
    BOOL _firstLoad;
    BOOL _testingFastAuth;
}

-(instancetype)init {
    NSString *resourceBundlePath = [[NSBundle mainBundle] pathForResource:@"PaypointResources" ofType:@"bundle"];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:resourceBundlePath];
    
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:resourceBundle];
    if (self) {
    }
    return self;
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
    NSLog(@"Finished");
    
    NSString *urlString = webView.request.URL.absoluteString;
    if ([urlString isEqualToString:self.termURLString]) {
        NSLog(@"match");
        NSString *string = [webView stringByEvaluatingJavaScriptFromString:@"get3DSData();"];
        id json = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
        NSString *pares = [json objectForKey:@"PaRes"];
        NSString *md = [json objectForKey:@"MD"];
        [self.delegate completed:pares transactionID:md];
    }
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Failed %@", error);
}

@end
