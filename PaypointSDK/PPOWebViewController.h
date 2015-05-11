//
//  PPOWebViewController.h
//  Paypoint
//
//  Created by Robert Nash on 26/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPOWebViewController;
@protocol PPOWebViewControllerDelegate <NSObject>
-(void)webViewController:(PPOWebViewController*)controller completedWithPaRes:(NSString*)paRes forTransactionWithID:(NSString*)transID;
-(void)webViewControllerUserCancelled:(PPOWebViewController*)controller;
-(void)webViewController:(PPOWebViewController*)controller failedWithError:(NSError*)error;
-(void)webViewControllerSessionTimeoutExpired:(PPOWebViewController*)controller;
-(void)webViewControllerDelayShowTimeoutExpired:(PPOWebViewController*)controller;
@end

@interface PPOWebViewController : UIViewController

//Holding strongly here
@property (nonatomic, strong) id <PPOWebViewControllerDelegate> delegate;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, copy) NSString *termURLString;
@property (nonatomic, strong) NSNumber *delayTimeInterval;
@property (nonatomic, strong) NSNumber *sessionTimeoutTimeInterval;
@end
