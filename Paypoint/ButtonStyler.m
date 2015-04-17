//
//  ButtonStyler.m
//  Paypoint
//
//  Created by Robert Nash on 17/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "ButtonStyler.h"
#import "ColourManager.h"
#import "ImageManager.h"

@implementation ButtonStyler

+(void)styleButton:(UIButton*)button {
    
    button.titleLabel.font = [UIFont systemFontOfSize:16.0f];
    
    UIColor *yellow = [ColourManager ppYellow];
    UIColor *blue = [ColourManager ppBlue];
    
    CGSize size = button.bounds.size;
    
    UIImage *image;
    
    image = [ImageManager fillImgOfSize:size
                              withColor:yellow];
    
    [button setBackgroundImage:image
                      forState:UIControlStateNormal];
    
    [button setTitleColor:yellow
                 forState:UIControlStateHighlighted];
    
    image = [ImageManager fillImgOfSize:size
                              withColor:blue];
    
    [button setBackgroundImage:image
                      forState:UIControlStateHighlighted];
    
    [button setTitleColor:blue
                 forState:UIControlStateNormal];
    
}

@end
