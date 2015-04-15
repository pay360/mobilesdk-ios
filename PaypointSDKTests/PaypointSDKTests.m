//
//  PaypointSDKTests.m
//  PaypointSDKTests
//
//  Created by Robert Nash on 20/03/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

//SDK
#import <PaypointSDK/PaypointSDK.h>

//Demo App
#import "NetworkManager.h"

@interface PaypointSDKTests : XCTestCase
@property (nonatomic, strong) NSArray *pans;
@property (nonatomic, strong) NSString *validBearerToken;
@property (nonatomic, strong) NSString *expiredBearerToken;
@property (nonatomic, strong) NSString *unauthorisedBearerToken;
@property (nonatomic, strong) PPOTransaction *transaction;
@property (nonatomic, strong) PPOCreditCard *card;
@property (nonatomic, strong) PPOBillingAddress *address;
@property (nonatomic, strong) PPOPaymentManager *paymentManager;
@property (nonatomic, strong) NSString *authorisedPan; //will generate an authorization result
@property (nonatomic, strong) NSString *declinePan; //will generate a decline result
@property (nonatomic, strong) NSString *delayAuthorisedPan; //will return a valid response but wait 61 seconds
@property (nonatomic, strong) NSString *serverErrorPan; //will return an internal server error
@property (nonatomic) PPOEnvironment currentEnvironment;
@end

@implementation PaypointSDKTests

- (void)setUp {
    [super setUp];
    
    self.validBearerToken = @"VALID_TOKEN";
    self.expiredBearerToken = @"EXPIRED_TOKEN";
    self.unauthorisedBearerToken = @"UNAUTHORISED_TOKEN";
    
    self.authorisedPan = @"9900000000005159";
    self.declinePan = @"9900000000005282";
    self.delayAuthorisedPan = @"9900000000000168";
    self.serverErrorPan = @"9900000000010407";
    
    self.pans = @[
                  self.authorisedPan,
                  self.declinePan,
                  self.delayAuthorisedPan,
                  self.serverErrorPan
                  ];
    
    self.address = [[PPOBillingAddress alloc] initWithFirstLine:nil
                                                 withSecondLine:nil
                                                  withThirdLine:nil
                                                 withFourthLine:nil
                                                       withCity:nil
                                                     withRegion:nil
                                                   withPostcode:nil
                                                withCountryCode:nil];
    
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    NSString *value = [environment objectForKey:@"ENVIRONMENT"];
    self.currentEnvironment = value.integerValue;
    
    
    self.paymentManager = [[PPOPaymentManager alloc] initForEnvironment:self.currentEnvironment];
}

- (void)tearDown {
    self.pans = nil;
    [super tearDown];
}

#pragma mark - Local Validation (Good Pan & Good Token)

-(void)testLuhn {
    for (NSString *pan in self.pans) NSAssert([PPOLuhn validateString:pan], @"Luhn check failed");
}

-(void)testSimplePaymentWithInvalidAmount {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment amount invalid"];
    
    self.transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                     withAmount:nil // < ---
                                                withDescription:@"A description"
                                          withMerchantReference:@"mer_txn_1234556"
                                                     isDeferred:NO];
    
    self.card = [[PPOCreditCard alloc] initWithPan:self.authorisedPan
                                          withCode:@"123"
                                        withExpiry:@"0116"
                                          withName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.validBearerToken];
    [self.paymentManager setCredentials:credentials];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome) {
        if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorPaymentAmountInvalid) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:60.0f handler:^(NSError *error) {
        
        if(error) {
            XCTFail(@"Simple payment failed with error: %@", error);
        }
        
    }];
    
}

-(void)testSimplePaymentWithInvalidCVV {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment card cvv invalid"];
    
    self.transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                     withAmount:@100
                                                withDescription:@"A description"
                                          withMerchantReference:@"mer_txn_1234556"
                                                     isDeferred:NO];
    
    self.card = [[PPOCreditCard alloc] initWithPan:self.authorisedPan
                                          withCode:nil // < ---
                                        withExpiry:@"0116"
                                          withName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.validBearerToken];
    [self.paymentManager setCredentials:credentials];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome) {
        if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorCVVInvalid) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:60.0f handler:^(NSError *error) {
        
        if(error) {
            XCTFail(@"Simple payment failed with error: %@", error);
        }
        
    }];
    
}

#pragma mark - Merchant Token Acquisition

-(void)testBearerTokenAcquisition {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Bearer token acquired"];
    
    [NetworkManager getCredentialsWithCompletion:^(PPOCredentials *credentials, NSURLResponse *response, NSError *error) {
        if (!error && credentials.token.length > 0) [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:60.0f handler:^(NSError *error) {
        
        if(error) {
            XCTFail(@"Bearer token acquisition failed with error: %@", error);
        }
        
    }];
}

#pragma mark - Good Pan & Good Token

-(void)testSimplePaymentWithAuthorisedPan {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment succeeded"];
    
    self.transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                     withAmount:@100
                                                withDescription:@"A description"
                                          withMerchantReference:@"mer_txn_1234556"
                                                     isDeferred:NO];
    
    self.card = [[PPOCreditCard alloc] initWithPan:self.authorisedPan
                                          withCode:@"123"
                                        withExpiry:@"0116"
                                          withName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.validBearerToken];
    [self.paymentManager setCredentials:credentials];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome) {
        if (!outcome.error) [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:60.0f handler:^(NSError *error) {
        
        if(error) {
            XCTFail(@"Simple payment failed with error: %@", error);
        }
        
    }];
    
}

#pragma mark - Good Pan & Bad Token

-(void)testSimplePaymentWithAuthorisedPanAndExpiredBearerToken {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment bearer token expired"];
    
    self.transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                     withAmount:@100
                                                withDescription:@"A description"
                                          withMerchantReference:@"mer_txn_1234556"
                                                     isDeferred:NO];
    
    self.card = [[PPOCreditCard alloc] initWithPan:self.authorisedPan
                                          withCode:@"123"
                                        withExpiry:@"0116"
                                          withName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.expiredBearerToken];
    [self.paymentManager setCredentials:credentials];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome) {
        if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorClientTokenExpired) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:60.0f handler:^(NSError *error) {
        
        if(error) {
            XCTFail(@"Simple payment failed with error: %@", error);
        }
        
    }];
    
}

-(void)testSimplePaymentWithAuthorisedPanAndUnauthorisedBearerToken {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment bearer token unauthorised"];
    
    self.transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                     withAmount:@100
                                                withDescription:@"A description"
                                          withMerchantReference:@"mer_txn_1234556"
                                                     isDeferred:NO];
    
    self.card = [[PPOCreditCard alloc] initWithPan:self.authorisedPan
                                          withCode:@"123"
                                        withExpiry:@"0116"
                                          withName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.unauthorisedBearerToken];
    [self.paymentManager setCredentials:credentials];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome) {
        if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorUnauthorisedRequest) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:60.0f handler:^(NSError *error) {
        
        if(error) {
            XCTFail(@"Simple payment failed with error: %@", error);
        }
        
    }];
    
}

#pragma mark - Good Token & Bad Pan

-(void)testSimplePaymentWithDeclinePan {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment processing failed"];
    
    self.transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                     withAmount:@100
                                                withDescription:@"A description"
                                          withMerchantReference:@"mer_txn_1234556"
                                                     isDeferred:NO];
    
    self.card = [[PPOCreditCard alloc] initWithPan:self.declinePan
                                          withCode:@"123"
                                        withExpiry:@"0116"
                                          withName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.validBearerToken];
    [self.paymentManager setCredentials:credentials];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome) {
        if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorTransactionProcessingFailed) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:60.0f handler:^(NSError *error) {
        
        if(error) {
            XCTFail(@"Simple payment failed with error: %@", error);
        }
        
    }];
    
}

//-(void)testSimplePaymentWithDelayedAuthorisedPan {
//    
//    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment timedout"];
//    
//    self.transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
//                                                     withAmount:@100
//                                                withDescription:@"A description"
//                                          withMerchantReference:@"mer_txn_1234556"
//                                                     isDeferred:NO];
//    
//    self.card = [[PPOCreditCard alloc] initWithPan:self.delayAuthorisedPan
//                                          withCode:@"123"
//                                        withExpiry:@"0116"
//                                          withName:@"John Smith"];
//    
//    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.validBearerToken];
//    [self.paymentManager setCredentials:credentials];
//    
//    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
//    
//    [self.paymentManager makePayment:payment withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome) {
//        if ([outcome.error.domain isEqualToString:@"NSURLErrorDomain"] && outcome.error.code == kCFURLErrorTimedOut) {
//            [expectation fulfill];
//        }
//    }];
//    
//    [self waitForExpectationsWithTimeout:61.5 handler:^(NSError *error) {
//        
//        if(error) {
//            XCTFail(@"Simple payment failed with error: %@", error);
//        }
//        
//    }];
//    
//}

-(void)testSimplePaymentWithServerErrorPan {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment server error"];
    
    self.transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                     withAmount:@100
                                                withDescription:@"A description"
                                          withMerchantReference:@"mer_txn_1234556"
                                                     isDeferred:NO];
    
    self.card = [[PPOCreditCard alloc] initWithPan:self.serverErrorPan
                                          withCode:@"123"
                                        withExpiry:@"0116"
                                          withName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.validBearerToken];
    [self.paymentManager setCredentials:credentials];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome) {
        if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorServerFailure) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:60.0f handler:^(NSError *error) {
        
        if(error) {
            XCTFail(@"Simple payment failed with error: %@", error);
        }
        
    }];
    
}

@end
