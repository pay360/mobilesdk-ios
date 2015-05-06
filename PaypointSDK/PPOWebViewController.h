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

//Holding strongly here
@property (nonatomic, strong) id <PPOWebViewControllerDelegate> delegate;
@property (nonatomic, strong) NSURLRequest *request;

-(instancetype)init;

@end
