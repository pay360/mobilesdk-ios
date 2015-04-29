//
//  PaypointLibraryTests.m
//  Paypoint
//
//  Created by Robert Nash on 23/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

//SDK
#import "Paypoint.h"

#define INSTALLATION_ID @"5300065"

@interface PaypointLibraryTests : XCTestCase
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

@implementation PaypointLibraryTests

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
    
    NSURL *baseURL = [PPOPaymentBaseURLManager baseURLForEnvironment:0];
    self.paymentManager = [[PPOPaymentManager alloc] initWithBaseURL:baseURL];
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
                              withSecurityCodeCode:@"123"
                                        withExpiry:@"0116"
                                withCardholderName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.validBearerToken];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withCredentials:credentials withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome, NSError *error) {
        if ([error.domain isEqualToString:PPOPaypointSDKErrorDomain] && error.code == PPOErrorPaymentAmountInvalid) {
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
                              withSecurityCodeCode:nil // < ---
                                        withExpiry:@"0116"
                                withCardholderName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.validBearerToken];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withCredentials:credentials withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome, NSError *error) {
        if ([error.domain isEqualToString:PPOPaypointSDKErrorDomain] && error.code == PPOErrorCVVInvalid) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:60.0f handler:^(NSError *error) {
        
        if(error) {
            XCTFail(@"Simple payment failed with error: %@", error);
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
                              withSecurityCodeCode:@"123"
                                        withExpiry:@"0116"
                                withCardholderName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.validBearerToken];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withCredentials:credentials withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome, NSError *error) {
        if (!error) [expectation fulfill];
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
                              withSecurityCodeCode:@"123"
                                        withExpiry:@"0116"
                                withCardholderName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.expiredBearerToken];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withCredentials:credentials withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome, NSError *error) {
        
        if ([error.domain isEqualToString:PPOPaypointSDKErrorDomain] && error.code == PPOErrorClientTokenExpired) {
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
                              withSecurityCodeCode:@"123"
                                        withExpiry:@"0116"
                                withCardholderName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.unauthorisedBearerToken];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withCredentials:credentials withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome, NSError *error) {
        
        if ([error.domain isEqualToString:PPOPaypointSDKErrorDomain] && error.code == PPOErrorUnauthorisedRequest) {
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
    
    self.card =     [[PPOCreditCard alloc] initWithPan:self.declinePan
                                  withSecurityCodeCode:@"123"
                                            withExpiry:@"0116"
                                    withCardholderName:@"John Smith"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.validBearerToken];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withCredentials:credentials withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome, NSError *error) {
        
        if ([error.domain isEqualToString:PPOPaypointSDKErrorDomain] && error.code == PPOErrorTransactionProcessingFailed) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:60.0f handler:^(NSError *error) {
        
        if(error) {
            XCTFail(@"Simple payment failed with error: %@", error);
        }
        
    }];
    
}

-(void)testSimplePaymentWithDelayedAuthorisedPan {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment timedout"];
    
    self.transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                     withAmount:@100
                                                withDescription:@"A description"
                                          withMerchantReference:@"mer_txn_1234556"
                                                     isDeferred:NO];
    
    self.card = [[PPOCreditCard alloc] initWithPan:self.delayAuthorisedPan
                              withSecurityCodeCode:@"123"
                                        withExpiry:@"0106"
                                withCardholderName:@"Dai Jones"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.validBearerToken];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withCredentials:credentials withTimeOut:1.0 withCompletion:^(PPOOutcome *outcome, NSError *error) {
        if ([error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == kCFURLErrorTimedOut) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        
        if(error) {
            XCTFail(@"Simple payment failed with error: %@", error);
        }
        
    }];
    
}

-(void)testSimplePaymentWithServerErrorPan {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment server error"];
    
    self.transaction = [[PPOTransaction alloc] initWithCurrency:@"GBP"
                                                     withAmount:@100
                                                withDescription:@"A description"
                                          withMerchantReference:@"mer_txn_1234556"
                                                     isDeferred:NO];
    
    self.card = [[PPOCreditCard alloc] initWithPan:self.serverErrorPan
                              withSecurityCodeCode:@"123"
                                        withExpiry:@"0116"
                                withCardholderName:@"Dai Jones"];
    
    PPOCredentials *credentials = [[PPOCredentials alloc] initWithID:INSTALLATION_ID withToken:self.validBearerToken];
    
    PPOPayment *payment = [[PPOPayment alloc] initWithTransaction:self.transaction withCard:self.card withBillingAddress:self.address];
    
    [self.paymentManager makePayment:payment withCredentials:credentials withTimeOut:60.0f withCompletion:^(PPOOutcome *outcome, NSError *error) {
        if ([error.domain isEqualToString:PPOPaypointSDKErrorDomain] && error.code == PPOErrorServerFailure) {
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