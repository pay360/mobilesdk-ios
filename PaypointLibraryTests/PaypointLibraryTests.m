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
    
    PPOBillingAddress *address = [PPOBillingAddress new];
    address.line1 = nil;
    address.line2 = nil;
    address.line3 = nil;
    address.line4 = nil;
    address.city = nil;
    address.region = nil;
    address.postcode = nil;
    address.countryCode = nil;
    
    self.address = address;
    
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

-(void)testBaseURLManager {
    
    NSURL *baseURL;
    
    for (PPOEnvironment e = PPOEnvironmentMerchantIntegrationTestingEnvironment; e < PPOEnvironmentTotalCount; e++) {
        
        baseURL = [PPOPaymentBaseURLManager baseURLForEnvironment:e];
        
        switch (e) {
            case PPOEnvironmentMerchantIntegrationTestingEnvironment:
                NSAssert([baseURL.absoluteString isEqualToString:@"http://localhost:5000"], @"Base URL unexpected");
                break;
                
            default:
                break;
        }
        
    }
    
}

-(void)testSimplePaymentWithInvalidAmount {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment amount invalid"];
    
    PPOTransaction *transaction = [PPOTransaction new];
    transaction.currency = @"GBP";
    transaction.amount = nil; // < ---
    transaction.transactionDescription = @"A desc";
    transaction.merchantRef = [NSString stringWithFormat:@"mer_%.0f", [[NSDate date] timeIntervalSince1970]];
    transaction.isDeferred = @NO;
    
    self.transaction = transaction;
    
    PPOCreditCard *card = [PPOCreditCard new];
    card.pan = self.authorisedPan;
    card.cvv = @"123";
    card.expiry = @"0116";
    card.cardHolderName = @"Dai Jones";
    
    self.card = card;
    
    PPOCredentials *credentials = [PPOCredentials new];
    credentials.installationID = INSTALLATION_ID;
    credentials.token = self.validBearerToken;
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = self.transaction;
    payment.card = self.card;
    payment.address = self.address;
    
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
    
    PPOTransaction *transaction = [PPOTransaction new];
    transaction.currency = @"GBP";
    transaction.amount = @100;
    transaction.transactionDescription = @"A desc";
    transaction.merchantRef = [NSString stringWithFormat:@"mer_%.0f", [[NSDate date] timeIntervalSince1970]];
    transaction.isDeferred = @NO;
    
    self.transaction = transaction;
    
    PPOCreditCard *card = [PPOCreditCard new];
    card.pan = self.authorisedPan;
    card.cvv = nil;
    card.expiry = @"0116";
    card.cardHolderName = @"Dai Jones";

    self.card = card;
    
    PPOCredentials *credentials = [PPOCredentials new];
    credentials.installationID = INSTALLATION_ID;
    credentials.token = self.validBearerToken;
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = self.transaction;
    payment.card = self.card;
    payment.address = self.address;
    
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
    
    PPOTransaction *transaction = [PPOTransaction new];
    transaction.currency = @"GBP";
    transaction.amount = @100;
    transaction.transactionDescription = @"A desc";
    transaction.merchantRef = [NSString stringWithFormat:@"mer_%.0f", [[NSDate date] timeIntervalSince1970]];
    transaction.isDeferred = @NO;
    
    self.transaction = transaction;
    
    PPOCreditCard *card = [PPOCreditCard new];
    card.pan = self.authorisedPan;
    card.cvv = @"123";
    card.expiry = @"0116";
    card.cardHolderName = @"Dai Jones";
    
    self.card = card;
    
    PPOCredentials *credentials = [PPOCredentials new];
    credentials.installationID = INSTALLATION_ID;
    credentials.token = self.validBearerToken;
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = self.transaction;
    payment.card = self.card;
    payment.address = self.address;
    
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
    
    PPOTransaction *transaction = [PPOTransaction new];
    transaction.currency = @"GBP";
    transaction.amount = @100;
    transaction.transactionDescription = @"A desc";
    transaction.merchantRef = [NSString stringWithFormat:@"mer_%.0f", [[NSDate date] timeIntervalSince1970]];
    transaction.isDeferred = @NO;
    
    self.transaction = transaction;
    
    PPOCreditCard *card = [PPOCreditCard new];
    card.pan = self.authorisedPan;
    card.cvv = @"123";
    card.expiry = @"0116";
    card.cardHolderName = @"Dai Jones";
    
    self.card = card;
    
    PPOCredentials *credentials = [PPOCredentials new];
    credentials.installationID = INSTALLATION_ID;
    credentials.token = self.expiredBearerToken;
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = self.transaction;
    payment.card = self.card;
    payment.address = self.address;
    
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
    
    PPOTransaction *transaction = [PPOTransaction new];
    transaction.currency = @"GBP";
    transaction.amount = @100;
    transaction.transactionDescription = @"A desc";
    transaction.merchantRef = [NSString stringWithFormat:@"mer_%.0f", [[NSDate date] timeIntervalSince1970]];
    transaction.isDeferred = @NO;

    self.transaction = transaction;
    
    PPOCreditCard *card = [PPOCreditCard new];
    card.pan = self.authorisedPan;
    card.cvv = @"123";
    card.expiry = @"0116";
    card.cardHolderName = @"Dai Jones";
    
    self.card = card;
    
    PPOCredentials *credentials = [PPOCredentials new];
    credentials.installationID = INSTALLATION_ID;
    credentials.token = self.unauthorisedBearerToken;
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = self.transaction;
    payment.card = self.card;
    payment.address = self.address;
    
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
    
    PPOTransaction *transaction = [PPOTransaction new];
    transaction.currency = @"GBP";
    transaction.amount = @100;
    transaction.transactionDescription = @"A desc";
    transaction.merchantRef = [NSString stringWithFormat:@"mer_%.0f", [[NSDate date] timeIntervalSince1970]];
    transaction.isDeferred = @NO;
    
    self.transaction = transaction;
    
    PPOCreditCard *card = [PPOCreditCard new];
    card.pan = self.declinePan;
    card.cvv = @"123";
    card.expiry = @"0116";
    card.cardHolderName = @"Dai Jones";
    
    self.card = card;
    
    PPOCredentials *credentials = [PPOCredentials new];
    credentials.installationID = INSTALLATION_ID;
    credentials.token = self.validBearerToken;
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = self.transaction;
    payment.card = self.card;
    payment.address = self.address;
    
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
    
    PPOTransaction *transaction = [PPOTransaction new];
    transaction.currency = @"GBP";
    transaction.amount = @100;
    transaction.transactionDescription = @"A desc";
    transaction.merchantRef = [NSString stringWithFormat:@"mer_%.0f", [[NSDate date] timeIntervalSince1970]];
    transaction.isDeferred = @NO;
    
    self.transaction = transaction;
    
    PPOCreditCard *card = [PPOCreditCard new];
    card.pan = self.delayAuthorisedPan;
    card.cvv = @"123";
    card.expiry = @"0116";
    card.cardHolderName = @"Dai Jones";
    
    self.card = card;
    
    PPOCredentials *credentials = [PPOCredentials new];
    credentials.installationID = INSTALLATION_ID;
    credentials.token = self.validBearerToken;
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = self.transaction;
    payment.card = self.card;
    payment.address = self.address;
    
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
    
    PPOTransaction *transaction = [PPOTransaction new];
    transaction.currency = @"GBP";
    transaction.amount = @100;
    transaction.transactionDescription = @"A desc";
    transaction.merchantRef = [NSString stringWithFormat:@"mer_%.0f", [[NSDate date] timeIntervalSince1970]];
    transaction.isDeferred = @NO;
    
    self.transaction = transaction;
    
    PPOCreditCard *card = [PPOCreditCard new];
    card.pan = self.serverErrorPan;
    card.cvv = @"123";
    card.expiry = @"0116";
    card.cardHolderName = @"Dai Jones";
    
    self.card = card;
    
    PPOCredentials *credentials = [PPOCredentials new];
    credentials.installationID = INSTALLATION_ID;
    credentials.token = self.validBearerToken;
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = self.transaction;
    payment.card = self.card;
    payment.address = self.address;
    
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