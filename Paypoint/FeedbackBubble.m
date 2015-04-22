//
//  FeedbackBubble.m
//  Paypoint
//
//  Created by Robert Nash on 21/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "FeedbackBubble.h"
#import "StyleKit.h"

@implementation FeedbackBubble

-(instancetype)initWithFrame:(CGRect)frame withMessage:(NSString *)message {
    self = [super initWithFrame:frame];
    if (self) {
        _message = message;
    }
    return self;
}

-(void)setMessage:(NSString *)message {
    if (![_message isEqualToString:message]) {
        _message = message;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect {
    [StyleKit drawFeedbackBubbleWithFrame:self.bounds message:self.message];
}

@end
