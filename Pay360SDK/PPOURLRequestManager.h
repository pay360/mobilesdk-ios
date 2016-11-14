//
//  PPOURLRequestManager.h
//  Pay360
//
//  Created by Robert Nash on 03/06/2015.
//  Copyright (c) 2016 Pay360 by Capita. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPOPayment;
@class PPODeviceInfo;
@interface PPOURLRequestManager : NSObject

+(NSURLRequest*)requestWithURL:(NSURL*)url
                    withMethod:(NSString*)method
                   withTimeout:(CGFloat)timeout
                     withToken:(NSString*)token
                      withBody:(NSData*)body
              forPaymentWithID:(NSString*)paymentID;

+(NSData*)buildPostBodyWithPayment:(PPOPayment*)payment
                    withDeviceInfo:(PPODeviceInfo*)deviceInfo ;

@end
