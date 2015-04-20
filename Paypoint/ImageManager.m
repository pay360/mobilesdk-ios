//
//  ImageManager.m
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "ImageManager.h"

@implementation ImageManager

+(UIImage*)fillImgOfSize:(CGSize)img_size withColor:(UIColor*)img_color {

    if (CGSizeEqualToSize(img_size, CGSizeZero)) {
        img_size = CGSizeMake(1, 1);
    }
    
    /* begin the graphic context */
    UIGraphicsBeginImageContextWithOptions(img_size, YES, 0);
    
    /* set the color */
    [img_color set];
    
    /* fill the rect */
    UIRectFill(CGRectMake(0, 0, img_size.width, img_size.height));
    
    /* get the image, end the context */
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    /* return the value */
    return scaledImage;
}

@end
