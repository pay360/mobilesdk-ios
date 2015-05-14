//
//  PPOWebViewController.h
//  Paypoint
//
//  Created by Robert Nash on 26/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPORedirect.h"

@class PPOWebViewController;
@protocol PPOWebViewControllerDelegate <NSObject>
-(void)webViewController:(PPOWebViewController*)controller completedWithPaRes:(NSString*)paRes forTransactionWithID:(NSString*)transID;
-(void)webViewControllerUserCancelled:(PPOWebViewController*)controller;
-(void)webViewController:(PPOWebViewController*)controller failedWithError:(NSError*)error;
-(void)webViewControllerSessionTimeoutExpired:(PPOWebViewController*)controller;
-(void)webViewControllerDelayShowTimeoutExpired:(PPOWebViewController*)controller;
@end

@interface PPOWebViewController : UIViewController
@property (nonatomic, strong) id <PPOWebViewControllerDelegate> delegate; //Holding strongly here
@property (nonatomic, strong) PPORedirect *redirect;

-(instancetype)initWithRedirect:(PPORedirect*)redirect withDelegate:(id<PPOWebViewControllerDelegate>)delegate;

@end
