//
//  PPOWebViewController.m
//  Paypoint
//
//  Created by Robert Nash on 26/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOWebViewController.h"

#define PAYPOINT_SDK_BUNDLE_URL [[NSBundle bundleForClass:[self class]] URLForResource:@"PaypointSDKBundle" withExtension:@"bundle"]

@interface PPOWebViewController () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSURLRequest *request;
@end

@implementation PPOWebViewController

-(instancetype)initWithRequest:(NSURLRequest*)request {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleWithURL:PAYPOINT_SDK_BUNDLE_URL]];
    if (self) {
        _request = request;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.webView loadRequest:self.request];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Failed %@", error);
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    NSString *scheme = request.URL.scheme;
    if ([scheme isEqualToString:@"appscheme"]) {
        
        NSString *string = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        NSArray *componenents = [string componentsSeparatedByString:@"&PaRes="];
        NSString *paRes = [self stringByDecodingURLFormat:componenents.lastObject];
        string = [self stringByDecodingURLFormat:componenents.firstObject];
        componenents = [string componentsSeparatedByString:@"MD="];
        string = componenents.lastObject;
        [self.delegate completed:paRes transactionID:string];
        return NO;
        
    }
    return YES;
}

- (NSString *)stringByDecodingURLFormat:(NSString*)urlString
{
    NSString *result = [urlString stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"Finished");
    
    NSCachedURLResponse *resp = [[NSURLCache sharedURLCache] cachedResponseForRequest:webView.request];
    id json = [NSJSONSerialization JSONObjectWithData:resp.data options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"%@",[(NSHTTPURLResponse*)resp.response allHeaderFields]);
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"Started");
}



@end
