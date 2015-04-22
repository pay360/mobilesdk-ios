//
//  FeedbackBubble.h
//  Paypoint
//
//  Created by Robert Nash on 21/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FeedbackBubble : UIView
@property (nonatomic, strong) NSString *message;

-(instancetype)initWithFrame:(CGRect)frame withMessage:(NSString*)message;

@end
