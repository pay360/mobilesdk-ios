//
//  PaypointSDKTests.m
//  PaypointSDKTests
//
//  Created by Robert Nash on 20/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <PaypointSDK/PPOLuhn.h>

@interface PaypointSDKTests : XCTestCase
@property (nonatomic, strong) NSArray *pans;
@end

@implementation PaypointSDKTests

- (void)setUp {
    [super setUp];
    
    self.pans = @[
                  @"9900000000005159", //with generate an authorization result
                  @"9900000000005282", //will generate a decline result
                  @"9900000000000168", //will return a valid response but wait 61 seconds
                  @"9900000000010407" //will return an internal server error
                  ];
}

- (void)tearDown {
    self.pans = nil;
    [super tearDown];
}

- (void)testLuhn {
    for (NSString *pan in self.pans) {
        NSAssert([PPOLuhn validateString:pan], @"Luhn check failed");
    }
}

@end
