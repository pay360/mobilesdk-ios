//
//  PPOWebViewController.h
//  Paypoint
//
//  Created by Robert Nash on 26/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PPOWebViewControllerDelegate <NSObject>
-(void)completed:(NSString*)paRes transactionID:(NSString*)transID;
@end

@interface PPOWebViewController : UIViewController

@property (nonatomic, weak) id <PPOWebViewControllerDelegate> delegate;

-(instancetype)initWithRequest:(NSURLRequest*)request;

@end
