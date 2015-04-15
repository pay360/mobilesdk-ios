//
//  ColourManager.m
//  Paypoint
//
//  Created by Robert Nash on 15/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "ColourManager.h"

@implementation ColourManager

+(UIColor*)ppYellow {
    return [UIColor colorWithRed:245/255.0f green:212/255.0f blue:14/255.0f alpha:1];
}

+(UIColor*)ppBlue {
    return [UIColor colorWithRed:46/255.0f green:37/255.0f blue:86/255.0f alpha:1];
}

+(UIColor*)ppLightGrey:(CGFloat)alpha {
    return [UIColor colorWithRed:165/255.0f green:157/255.0f blue:149/255.0f alpha:alpha];
}

@end
