//
//  PaymentManager.h
//  Paypoint
//
//  Created by Robert Nash on 20/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentControllerProtocol.h"
#import "PPOPaymentForm.h"

@interface PPOPaymentController : NSObject

@property (nonatomic, strong, readonly) NSOperationQueue *paymentQueue;

+(UINavigationController*)paymentFlowWithDelegate:(id<PPOPaymentControllerProtocol>)delegate;

+(NSURLRequest*)requestWithCredentials:(NSURL*)url;

+(void)postCard:(NSString*)card
        withCVV:(NSString*)cvv
     withExpiry:(NSString*)expiry
  using3DSecure:(BOOL)secure
 withCompletion:(void(^)(NSString *message, NSURL *redirect, NSData *data))completion;

+(void)resumePayment:(NSString*)paRes
   withTransactionID:(NSString*)transID
      withCompletion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completion;

@end
