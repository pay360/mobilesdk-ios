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

#define VALID_BEARER_TOKEN @"VALID_TOKEN"
#define EXPIRED_BEARER_TOKEN @"EXPIRED_TOKEN"
#define UNAUTHORISED_BEARER_TOKEN @"UNAUTHORISED_TOKEN"
#define AUTHORISED_PAN @"9900000000005159"
#define DECLINE_PAN @"9900000000005282"
#define DELAY_AUTHORISED_PAN @"9900000000000168"
#define SERVER_ERROR_PAN @"9900000000010407"

@interface PaypointLibraryTests : XCTestCase
@property (nonatomic, strong) NSArray *pans;
@property (nonatomic) PPOEnvironment currentEnvironment;
@end

@implementation PaypointLibraryTests

- (void)setUp {
    [super setUp];
    
    self.pans = @[
                  AUTHORISED_PAN,
                  DECLINE_PAN,
                  DELAY_AUTHORISED_PAN,
                  SERVER_ERROR_PAN
                  ];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Local Validation (Good Pan & Good Token)

-(void)testLuhn {
    
    for (NSString *pan in self.pans) {
        NSAssert([PPOLuhn validateString:pan], @"Luhn check failed");
    }
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

-(void)testPaymentWithFinancialServicesAndCustomer {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Valid payment with financial services"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:AUTHORISED_PAN];
    payment.customer = [self customer];
    payment.financialServices = [self financialServices];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:[PPOPaymentBaseURLManager baseURLForEnvironment:0]];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if (!outcome.error) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
    
}

-(void)testSimplePaymentWithInvalidAmount {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment amount invalid"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:nil];
    payment.card = [self creditCardWithPan:AUTHORISED_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:[PPOPaymentBaseURLManager baseURLForEnvironment:0]];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorPaymentAmountInvalid) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
    
}

-(void)testSimplePaymentWithCustomFields {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment amount invalid"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:AUTHORISED_PAN];
    payment.customFields = [self customFields];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:[PPOPaymentBaseURLManager baseURLForEnvironment:0]];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if (!outcome.error && outcome.customFields.count == 3) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
    
}

-(void)testSimplePaymentWithInvalidCVV {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment card cvv invalid"];
    
    PPOCreditCard *card = [self creditCardWithPan:AUTHORISED_PAN];
    card.cvv = nil;
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = card;
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:[PPOPaymentBaseURLManager baseURLForEnvironment:0]];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorCVVInvalid) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
}

-(void)testSimplePaymentWithAuthorisedPan {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment succeeded"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:AUTHORISED_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:[PPOPaymentBaseURLManager baseURLForEnvironment:0]];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if (!outcome.error) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
    
}

-(void)testSimplePaymentWithExpiredBearerToken {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment bearer token expired"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:AUTHORISED_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:[PPOPaymentBaseURLManager baseURLForEnvironment:0]];
    
    payment.credentials = [self credentialsWithToken:EXPIRED_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorClientTokenExpired) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
    
}

-(void)testSimplePaymentWithUnauthorisedBearerToken {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment bearer token unauthorised"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:AUTHORISED_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:[PPOPaymentBaseURLManager baseURLForEnvironment:0]];
    
    payment.credentials = [self credentialsWithToken:UNAUTHORISED_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorUnauthorisedRequest) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
}

#pragma mark - Good Token & Bad Pan

-(void)testSimplePaymentWithDeclinePan {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment processing failed"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:DECLINE_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:[PPOPaymentBaseURLManager baseURLForEnvironment:0]];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorTransactionDeclined) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
}

-(void)testSimplePaymentWithDeclinePanWithCustomFields {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment processing failed"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:DECLINE_PAN];
    payment.customFields = [self customFields];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:[PPOPaymentBaseURLManager baseURLForEnvironment:0]];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if (outcome.customFields.count > 0) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
}

/**
 *  Network returns a valid response after 2 second delay.
 *  We cancel the network task associated with this payment after a 1 second timeout.
 */
-(void)testSessionTimeout {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment timedout"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:DELAY_AUTHORISED_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:[PPOPaymentBaseURLManager baseURLForEnvironment:0]];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:1.0
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorMasterSessionTimedOut) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:3.0
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
}

-(void)testSimplePaymentWithServerErrorPan {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple payment server error"];
    
    PPOPayment *payment = [PPOPayment new];
    payment.transaction = [self transactionWithAmount:@100];
    payment.card = [self creditCardWithPan:SERVER_ERROR_PAN];
    
    PPOPaymentManager *manager = [[PPOPaymentManager alloc] initWithBaseURL:[PPOPaymentBaseURLManager baseURLForEnvironment:0]];
    
    payment.credentials = [self credentialsWithToken:VALID_BEARER_TOKEN];
    
    [manager makePayment:payment
             withTimeOut:60.0f
          withCompletion:^(PPOOutcome *outcome) {
              if ([outcome.error.domain isEqualToString:PPOPaypointSDKErrorDomain] && outcome.error.code == PPOErrorServerFailure) {
                  [expectation fulfill];
              }
          }];
    
    [self waitForExpectationsWithTimeout:60.0f
                                 handler:^(NSError *error) {
                                     if(error) {
                                         XCTFail(@"Simple payment failed with error: %@", error);
                                     }
                                 }];
}

-(PPOTransaction*)transactionWithAmount:(NSNumber*)amount {
    PPOTransaction *transaction;
    transaction = [PPOTransaction new];
    transaction.currency = @"GBP";
    transaction.amount = amount;
    transaction.transactionDescription = @"A desc";
    transaction.merchantRef = [NSString stringWithFormat:@"mer_%.0f", [[NSDate date] timeIntervalSince1970]];
    transaction.isDeferred = @NO;
    return transaction;
}

-(PPOCreditCard*)creditCardWithPan:(NSString*)pan {
    PPOCreditCard *card = [PPOCreditCard new];
    card.pan = pan;
    card.cvv = @"123";
    card.expiry = @"0116";
    card.cardHolderName = @"Dai Jones";
    return card;
}

-(PPOFinancialServices*)financialServices {
    PPOFinancialServices *financialServices = [PPOFinancialServices new];
    financialServices.dateOfBirth = @"19870818";
    financialServices.surname = @"Smith";
    financialServices.accountNumber = @"123ABC";
    financialServices.postCode = @"BS20";
    return financialServices;
}

-(PPOCustomer*)customer {
    PPOCustomer *customer = [PPOCustomer new];
    customer.email = @"test@paypoint.com";
    customer.dateOfBirth = @"1900-01-01";
    customer.telephone = @"01225 123456";
    return customer;
}

-(PPOCredentials*)credentialsWithToken:(NSString*)token {
    PPOCredentials *credentials = [PPOCredentials new];
    credentials.token = token;
    return credentials;
}

-(NSSet*)customFields {
    NSMutableSet *collector = [NSMutableSet new];
    
    PPOCustomField *customField;
    customField = [PPOCustomField new];
    customField.name = @"CustomName";
    customField.value = @"CustomValue";
    customField.isTransient = @YES;
    
    [collector addObject:customField];
    
    customField = [PPOCustomField new];
    customField.name = @"CustomName";
    
    [collector addObject:customField];
    
    customField = [PPOCustomField new];
    customField.name = @"AnotherCustomName";
    customField.isTransient = @YES;
    
    [collector addObject:customField];
    
    return [collector copy];
}

@end